package com.example.bangun_yuk

import android.os.Bundle
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import androidx.annotation.NonNull

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = NotificationChannelCompat.Builder(
            "alarm_channel",
            NotificationManagerCompat.IMPORTANCE_HIGH
        )
            .setName("Alarm Notifications")
            .setDescription("Channel for alarm notifications")
            .setSound(null, null)
            .build()

        NotificationManagerCompat.from(this).createNotificationChannel(channel)
    }
}
