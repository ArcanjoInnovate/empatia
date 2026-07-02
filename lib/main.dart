import 'package:empatia/core/service/notification_display_service.dart';
import 'package:empatia/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Esconde a barra de navegação nativa do Android (botões voltar/home/recentes).
  // immersiveSticky: some até o usuário arrastar da borda — e re-aparece
  // brevemente, depois some de novo. O observer em MyApp reaaplica ao voltar
  // ao foco (Android reseta após dialogs, teclado, notificações, etc.).
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  // Inicializa o Firebase UMA única vez aqui no Dart.
  // O AppDelegate.swift NÃO deve chamar FirebaseApp.configure(),
  // pois isso causava double-initialization → crash ao abrir o app.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa o serviço de notificação — cobre o banner interno (app
  // aberto) e a navegação ao tocar. Notificação de sistema em
  // background/fechado volta a ser 100% padrão do FCM/Android — não
  // precisa de nenhum handler nosso pra isso.
  await NotificationDisplayService.instance.init();

  // Cenário "app fechado de vez, usuário abriu tocando na notificação"
  // — só dá pra checar isso DEPOIS que o primeiro frame (e portanto o
  // Navigator) já estiver montado, senão não tem pra onde navegar.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    NotificationDisplayService.instance.checkLaunchedFromNotification();
  });

  print('teste');
  // Desativa verificação de reCAPTCHA/Play Integrity em debug.
  if (kDebugMode) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }

  runApp(const MyApp());
}