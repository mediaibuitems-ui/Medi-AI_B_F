package io.flutter.plugins

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.example.medi_ai.MainActivity

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.d("BootReceiver", "Device boot completed, attempting to reschedule medicine reminders")
            
            // Start the app's main activity
            val mainIntent = Intent(context, MainActivity::class.java)
            mainIntent.action = "reschedule_reminders"
            mainIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            context.startActivity(mainIntent)
        }
    }
}

