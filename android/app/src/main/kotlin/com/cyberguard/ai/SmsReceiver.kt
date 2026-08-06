package com.cyberguard.ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsMessage

/// Receives incoming SMS broadcasts, hands { address, body, date } to the
/// Dart-side EventChannel via [SmsBus], and runs the native background scan
/// through [SmsGuard].
///
/// Declared in the manifest rather than registered dynamically. SMS_RECEIVED
/// sits on the implicit-broadcast allowlist, so a manifest receiver is still
/// delivered to on modern Android — the process is started for it if nothing
/// is running. That is what let the resident foreground service go.
///
/// It must be registered in exactly one place: a manifest entry *and* a
/// dynamic registration would both fire, scanning every message twice and
/// raising duplicate notifications.
class SmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return
        try {
            val pdus = intent.extras?.get("pdus") as? Array<*> ?: return
            val format = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                intent.getStringExtra("format")
            } else null

            // Group multi-part SMS into a single body per sender.
            val grouped = mutableMapOf<String, StringBuilder>()
            var ts: Long = System.currentTimeMillis()

            for (pdu in pdus) {
                val sms = if (format != null) {
                    SmsMessage.createFromPdu(pdu as ByteArray, format)
                } else {
                    @Suppress("DEPRECATION")
                    SmsMessage.createFromPdu(pdu as ByteArray)
                } ?: continue
                val sender = sms.originatingAddress ?: ""
                val body = sms.messageBody ?: ""
                grouped.getOrPut(sender) { StringBuilder() }.append(body)
                ts = sms.timestampMillis.takeIf { it > 0 } ?: ts
            }

            for ((sender, body) in grouped) {
                val event = mapOf<String, Any?>(
                    "address" to sender,
                    "body" to body.toString(),
                    "date" to ts.toString(),
                )
                // Live in-app UI (buffered until the Dart sink attaches).
                SmsBus.publish(event)
                // Background scan. No-ops unless the user enabled the guard,
                // and runs here rather than in a service because this may be
                // the only thing the process was started for.
                SmsGuard.handle(context.applicationContext, event)
            }
        } catch (_: Throwable) {
            // Never crash the system broadcast pipeline.
        }
    }
}

/// Singleton fan-out from the receiver to (a) the EventChannel sink set up
/// in MainActivity for live in-app UI updates, and (b) any number of native
/// "taps".
///
/// The taps list is vestigial: the background scanner used to subscribe here
/// from a foreground service, and now [SmsReceiver] calls [SmsGuard] directly.
/// It is kept because it is the natural extension point for any future native
/// subscriber, and costs nothing while empty.
///
/// Multiple SMS can arrive while the Dart engine is still attaching, so we
/// buffer the last N events for the Dart sink and replay on attach.
object SmsBus {
    private const val BUFFER_LIMIT = 20
    private val buffer = ArrayDeque<Map<String, Any?>>()
    private var sink: io.flutter.plugin.common.EventChannel.EventSink? = null
    private val taps = mutableListOf<(Map<String, Any?>) -> Unit>()

    @Synchronized
    fun attach(s: io.flutter.plugin.common.EventChannel.EventSink) {
        sink = s
        while (buffer.isNotEmpty()) {
            s.success(buffer.removeFirst())
        }
    }

    @Synchronized
    fun detach() {
        sink = null
    }

    /// Native subscriber — receives every event the moment it arrives.
    @Synchronized
    fun tap(handler: (Map<String, Any?>) -> Unit) {
        taps += handler
    }

    @Synchronized
    fun untapAll() {
        taps.clear()
    }

    @Synchronized
    fun publish(event: Map<String, Any?>) {
        // Native taps first — they never block, never throw.
        for (t in taps.toList()) {
            try { t(event) } catch (_: Throwable) {}
        }
        // Then the Dart sink (if attached) or buffer.
        val s = sink
        if (s != null) {
            s.success(event)
        } else {
            if (buffer.size >= BUFFER_LIMIT) buffer.removeFirst()
            buffer.addLast(event)
        }
    }
}
