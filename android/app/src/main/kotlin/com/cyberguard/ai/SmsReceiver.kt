package com.cyberguard.ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Telephony
import android.telephony.SmsMessage

/// Receives incoming SMS broadcasts and forwards { address, body, date }
/// to whatever Dart-side EventChannel listener is registered through
/// [SmsBus]. Registered dynamically by MainActivity so the receiver is
/// only active while the app is running (no manifest receiver = no
/// implicit-broadcast Android 14 restriction).
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
                SmsBus.publish(
                    mapOf(
                        "address" to sender,
                        "body" to body.toString(),
                        "date" to ts.toString(),
                    )
                )
            }
        } catch (_: Throwable) {
            // Never crash the system broadcast pipeline.
        }
    }
}

/// Singleton fan-out from the receiver to (a) the EventChannel sink set up
/// in MainActivity for live in-app UI updates, and (b) any number of native
/// "taps" — used by [PhishingGuardService] so the background scanner sees
/// every SMS too.
///
/// Multiple SMS can arrive while the Dart engine is still attaching, so we
/// buffer the last N events for the Dart sink and replay on attach. Native
/// taps don't need buffering — they're registered before the receiver fires.
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
