package com.cyberguard.ai

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/// Restarts the [PhishingGuardService] after device boot, *only* if the
/// user previously enabled the SMS guard. This avoids running a foreground
/// service unannounced for fresh installs.
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON") return
        if (PhishingGuardService.isEnabled(context)) {
            PhishingGuardService.start(context)
        }
    }
}
