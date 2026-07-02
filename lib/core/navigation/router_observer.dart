// lib/core/navigation/route_observer.dart
//
// RouteObserver global — permite que widgets como o WeeklyRankingWidget
// saibam quando deixam de estar visíveis (outra página foi empurrada por
// cima) e quando voltam a ficar visíveis (a página de cima foi removida),
// via RouteAware (didPushNext / didPopNext).
//
// Precisa ser registrado em navigatorObservers no MaterialApp (ver app.dart).

import 'package:flutter/material.dart';

final RouteObserver<PageRoute> appRouteObserver = RouteObserver<PageRoute>();

/// Chave global do Navigator — permite navegar (ex: abrir um chat) a
/// partir de código que não tem um BuildContext de tela à mão, como o
/// callback de toque numa notificação local (NotificationDisplayService),
/// que pode disparar até com o app inteiro em background.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();