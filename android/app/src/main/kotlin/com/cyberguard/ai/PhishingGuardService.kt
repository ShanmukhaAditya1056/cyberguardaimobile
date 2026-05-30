package com.cyberguard.ai

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.SharedPreferences
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.provider.Telephony
import androidx.core.app.NotificationCompat

/// Long-lived foreground service that keeps an SMS receiver alive even after
/// the user kills the host activity. Every incoming SMS is scanned natively
/// in [NativePhishingDetector]; if a phishing link is detected, the service
/// fires a high-priority notification and records the hit for the Dart side
/// to pick up next time it launches.
///
/// All detection runs on-device — no network, no Dart isolate spin-up.
class PhishingGuardService : Service() {

    companion object {
        private const val CHANNEL_GUARD = "cyberguard_guard"
        private const val CHANNEL_ALERTS = "cyberguard_alerts"
        private const val GUARD_NOTIF_ID = 4242
        private const val PREFS = "cyberguard_guard_prefs"
        const val PREF_ENABLED = "guard_enabled"
        private const val PREF_HIT_COUNT = "hit_count"

        fun start(context: Context) {
            val intent = Intent(context, PhishingGuardService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putBoolean(PREF_ENABLED, true).apply()
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, PhishingGuardService::class.java))
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putBoolean(PREF_ENABLED, false).apply()
        }

        fun isEnabled(context: Context): Boolean {
            return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean(PREF_ENABLED, false)
        }
    }

    private val smsReceiver = SmsReceiver()
    private var registered = false
    private lateinit var prefs: SharedPreferences

    override fun onCreate() {
        super.onCreate()
        prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        ensureChannels()
        startInForeground()
        registerReceiver()
        // Also fan-out every received SMS to our native phishing scanner
        // (in addition to the EventChannel sink used while the app is up).
        SmsBus.tap { event -> scan(event) }
    }

    private fun ensureChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = getSystemService(NotificationManager::class.java)
        if (mgr.getNotificationChannel(CHANNEL_GUARD) == null) {
            mgr.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_GUARD,
                    "CyberGuard SMS Guard",
                    NotificationManager.IMPORTANCE_LOW
                ).apply { description = "Persistent SMS phishing protection" }
            )
        }
        if (mgr.getNotificationChannel(CHANNEL_ALERTS) == null) {
            mgr.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ALERTS,
                    "CyberGuard Threat Alerts",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Critical threat notifications"
                    enableVibration(true)
                }
            )
        }
    }

    private fun startInForeground() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pi = if (launchIntent != null) {
            PendingIntent.getActivity(
                this, 0, launchIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        } else null

        val hits = prefs.getInt(PREF_HIT_COUNT, 0)
        val notif: Notification = NotificationCompat.Builder(this, CHANNEL_GUARD)
            .setContentTitle("CyberGuard SMS Guard")
            .setContentText(
                if (hits == 0)
                    "Scanning every incoming SMS for phishing links"
                else
                    "Blocked $hits suspicious link${if (hits == 1) "" else "s"}"
            )
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(pi)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                GUARD_NOTIF_ID, notif,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
            )
        } else {
            startForeground(GUARD_NOTIF_ID, notif)
        }
    }

    private fun registerReceiver() {
        if (registered) return
        val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
            .apply { priority = 999 }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(smsReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(smsReceiver, filter)
        }
        registered = true
    }

    private fun scan(event: Map<String, Any?>) {
        val body = (event["body"] as? String) ?: return
        val sender = (event["address"] as? String) ?: "Unknown"
        val verdict = NativePhishingDetector.check(body) ?: return
        if (!verdict.isPhishing) return

        // Bump hit counter so the persistent notification reflects it.
        val newHits = prefs.getInt(PREF_HIT_COUNT, 0) + 1
        prefs.edit().putInt(PREF_HIT_COUNT, newHits).apply()
        startInForeground() // refresh the ongoing notification

        // Pop a high-priority alert.
        val mgr = getSystemService(NotificationManager::class.java)
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pi = if (launchIntent != null) {
            PendingIntent.getActivity(
                this, verdict.url.hashCode(), launchIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        } else null

        val alert = NotificationCompat.Builder(this, CHANNEL_ALERTS)
            .setContentTitle("Suspicious SMS from $sender")
            .setContentText("Possible phishing link: ${verdict.url.take(60)}…")
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    "Possible phishing link: ${verdict.url}\n\n" +
                            "Reason: ${verdict.reason}"
                )
            )
            .setSmallIcon(android.R.drawable.stat_sys_warning)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(pi)
            .build()
        mgr.notify(verdict.url.hashCode(), alert)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY // restart if the OS kills us
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        SmsBus.untapAll()
        if (registered) {
            try { unregisterReceiver(smsReceiver) } catch (_: Throwable) {}
            registered = false
        }
        super.onDestroy()
    }
}

/// Native phishing rules — mirror of the Dart engine but cheap enough
/// to run on the SMS broadcast thread. Returns null for "no URL found",
/// otherwise a verdict with the offending URL + reason.
data class PhishingVerdict(
    val url: String,
    val isPhishing: Boolean,
    val reason: String,
)

object NativePhishingDetector {
    private val URL_REGEX = Regex(
        """((https?://)?[a-z0-9][a-z0-9.\-]*\.[a-z]{2,}(/[^\s]*)?)""",
        RegexOption.IGNORE_CASE
    )

    private val trustedDomains = listOf(
        "google.com", "youtube.com", "gmail.com", "google.co.in",
        "paytm.com", "phonepe.com", "gpay.com", "npci.org.in",
        "sbi.co.in", "onlinesbi.sbi", "hdfcbank.com", "icicibank.com",
        "axisbank.com", "kotak.com", "amazon.in", "amazon.com",
        "flipkart.com", "myntra.com", "swiggy.com", "zomato.com",
        "ola.com", "uber.com", "jio.com", "airtel.in",
        "irctc.co.in", "uidai.gov.in", "incometax.gov.in",
        "whatsapp.com", "instagram.com", "facebook.com",
        "microsoft.com", "apple.com",
    )

    private val dangerousTlds = listOf(
        ".xyz", ".tk", ".ml", ".ga", ".cf", ".click", ".top",
        ".loan", ".gq", ".pw", ".buzz", ".link", ".site",
    )

    private val phishingKeywords = listOf(
        "verify-now", "verify-account", "kyc-update", "kyc-verify",
        "aadhaar-verify", "pan-verify", "otp-confirm",
        "upi-reward", "claim-prize", "you-won", "free-jio",
        "sim-block", "tax-refund", "account-suspended",
        "expire-today", "click-now", "free-recharge",
        "secure-hdfc", "sbi-alert", "paytm-blocked",
        "phonepe-verify", "gpay-verify",
    )

    fun check(text: String): PhishingVerdict? {
        val match = URL_REGEX.find(text) ?: return null
        val url = match.value.lowercase()
        val host = url
            .replace(Regex("""^https?://"""), "")
            .substringBefore('/')

        // Whitelist
        if (trustedDomains.any { host == it || host.endsWith(".$it") }) {
            return PhishingVerdict(url, false, "Trusted domain")
        }

        var score = 0
        val reasons = mutableListOf<String>()

        // Dangerous TLD
        dangerousTlds.firstOrNull { host.endsWith(it) }?.let {
            score += 35
            reasons += "Suspicious TLD $it"
        }

        // Keywords
        phishingKeywords.firstOrNull { url.contains(it) }?.let {
            score += 30
            reasons += "Phishing keyword \"$it\""
        }

        // Brand impersonation
        val brands = listOf(
            "paytm", "phonepe", "sbi", "hdfc", "icici", "axis",
            "amazon", "flipkart", "jio", "airtel", "aadhaar",
        )
        brands.firstOrNull { url.contains(it) &&
                !trustedDomains.any { d -> host == d || host.endsWith(".$d") } }
            ?.let {
                score += 30
                reasons += "Brand impersonation: $it"
            }

        // @ trick
        if (url.contains('@')) {
            score += 30
            reasons += "@ symbol used to hide real domain"
        }

        // IP address
        if (Regex("""^\d{1,3}(\.\d{1,3}){3}""").containsMatchIn(host)) {
            score += 30
            reasons += "IP address instead of domain"
        }

        // Too many hyphens
        val hyphens = host.count { it == '-' }
        if (hyphens >= 3) {
            score += hyphens * 5
            reasons += "Excessive hyphens ($hyphens)"
        }

        if (score < 35) return PhishingVerdict(url, false, "Likely safe")
        return PhishingVerdict(url, true, reasons.joinToString(" · "))
    }
}
