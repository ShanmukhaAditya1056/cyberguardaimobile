package com.cyberguard.ai

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat

/// Background SMS phishing guard.
///
/// This used to be a permanently-resident foreground service that existed
/// purely to keep a *dynamically* registered SmsReceiver alive. That cost a
/// process pinned in memory for the lifetime of the install, an ongoing
/// notification the user could not dismiss, a BootReceiver to restart it, and
/// a FOREGROUND_SERVICE_DATA_SYNC declaration that does not honestly describe
/// scanning SMS — a mismatch Android 14+ is increasingly strict about.
///
/// None of it was necessary. SMS_RECEIVED is on the implicit-broadcast
/// allowlist, so a receiver declared in the manifest is delivered to even when
/// no part of the app is running — Android starts the process for it. The
/// receiver now calls straight into [handle] and the service is gone.
///
/// Detection is the same [NativePhishingDetector] as before: pure regex and
/// string work, no Dart isolate, no network, comfortably inside the
/// onReceive budget.
object SmsGuard {
    private const val CHANNEL_ALERTS = "cyberguard_alerts"
    private const val PREFS = "cyberguard_guard_prefs"
    const val PREF_ENABLED = "guard_enabled"
    private const val PREF_HIT_COUNT = "hit_count"

    /// Opt-in, and defaults to off: a security app must not start reading SMS
    /// because it happened to be installed.
    fun isEnabled(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getBoolean(PREF_ENABLED, false)

    fun setEnabled(context: Context, enabled: Boolean) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putBoolean(PREF_ENABLED, enabled).apply()
    }

    fun hitCount(context: Context): Int =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getInt(PREF_HIT_COUNT, 0)

    /// Scan one received message and notify if it carries a phishing link.
    ///
    /// Called from [SmsReceiver.onReceive], which may be running in a process
    /// Android started solely to deliver this broadcast — so everything here
    /// takes a Context and holds no state of its own.
    fun handle(context: Context, event: Map<String, Any?>) {
        if (!isEnabled(context)) return
        val body = (event["body"] as? String) ?: return
        val sender = (event["address"] as? String) ?: "Unknown"

        val verdict = NativePhishingDetector.check(body) ?: return
        if (!verdict.isPhishing) return

        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        prefs.edit().putInt(PREF_HIT_COUNT, prefs.getInt(PREF_HIT_COUNT, 0) + 1).apply()

        ensureChannel(context)

        val launchIntent =
            context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pi = if (launchIntent != null) {
            PendingIntent.getActivity(
                context, verdict.url.hashCode(), launchIntent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
        } else null

        val alert = NotificationCompat.Builder(context, CHANNEL_ALERTS)
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

        NotificationManagerCompatNotify(context, verdict.url.hashCode(), alert)
    }

    private fun NotificationManagerCompatNotify(
        context: Context,
        id: Int,
        notification: android.app.Notification,
    ) {
        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as? NotificationManager ?: return
        try {
            mgr.notify(id, notification)
        } catch (_: SecurityException) {
            // POST_NOTIFICATIONS not granted on Android 13+.
        }
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as? NotificationManager ?: return
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
