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