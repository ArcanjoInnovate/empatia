// lib/features/notifications/controller/notification_controller.dart

import 'dart:async';
import 'package:empatia/features/notification/data/model/notification_model.dart';
import 'package:flutter/foundation.dart';
import '../data/repository/notification_repository.dart';

class NotificationController extends ChangeNotifier {
  NotificationController({required this.uid});

  final String uid;
  final _repo = NotificationRepository.instance;

  List<AppNotification> _personal  = [];
  AppNotification?      _broadcast;
  bool                  _loading   = true;
  int                   _unread    = 0;

  StreamSubscription? _personalSub;
  StreamSubscription? _broadcastSub;

  List<AppNotification> get personal  => _personal;
  AppNotification?      get broadcast => _broadcast;
  bool                  get loading   => _loading;
  int                   get unreadCount => _unread;

  /// Lista mesclada para exibir na tela: broadcast no topo (se existir),
  /// seguido das pessoais em ordem cronológica reversa.
  List<AppNotification> get all {
    final list = <AppNotification>[..._personal];
    if (_broadcast != null && !_broadcast!.read) {
      list.insert(0, _broadcast!);
    }
    return list;
  }

  void init() {
    _personalSub = _repo.userNotificationsStream(uid).listen((list) {
      _personal = list;
      _recalcUnread();
      if (_loading) {
        _loading = false;
      }
      notifyListeners();
    });

    _broadcastSub = _repo.broadcastStream().listen((n) {
      _broadcast = n;
      _recalcUnread();
      notifyListeners();
    });
  }

  void _recalcUnread() {
    final personalUnread = _personal.where((n) => !n.read).length;
    final broadcastUnread = (_broadcast != null && !_broadcast!.read) ? 1 : 0;
    _unread = personalUnread + broadcastUnread;
  }

  Future<void> markAsRead(AppNotification n) async {
    if (n.id == 'broadcast') {
      // Broadcast: marca localmente apenas (não escreve no RTDB para todos)
      _broadcast = n.copyWith(read: true);
      _recalcUnread();
      notifyListeners();
      return;
    }
    await _repo.markAsRead(uid, n.id);
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead(uid);
    if (_broadcast != null) {
      _broadcast = _broadcast!.copyWith(read: true);
    }
    _recalcUnread();
    notifyListeners();
  }

  @override
  void dispose() {
    _personalSub?.cancel();
    _broadcastSub?.cancel();
    super.dispose();
  }
}