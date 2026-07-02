package com.empatia.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )

        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

            // Canal "ação necessária" — pedidos de confirmação de entrega e
            // afins, que bloqueiam a conclusão até o usuário responder.
            // Mantém o nome/id original pra não perder as preferências que
            // o usuário já configurou pra esse canal no Android.
            val actionChannel = NotificationChannel(
                "empatia_notifications",
                "Ações pendentes",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Pedidos de confirmação e ações que precisam de resposta"
                enableLights(true)
                lightColor = Color.BLUE
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 250, 250, 250)
            }
            manager.createNotificationChannel(actionChannel)

            // Canal "informativo" — mensagens de chat, doação concluída,
            // etc. Importância mais baixa: aparece na lista/badge, mas
            // sem som/vibração forte a cada evento.
            val infoChannel = NotificationChannel(
                "empatia_info",
                "Atualizações",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Mensagens e atualizações gerais do app"
                enableLights(false)
                enableVibration(false)
            }
            manager.createNotificationChannel(infoChannel)
        }
    }
}