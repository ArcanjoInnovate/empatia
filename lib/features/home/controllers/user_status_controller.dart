// lib/features/home/controllers/user_stats_controller.dart

import 'package:empatia/features/home/data/repositories/user_stats_repository.dart';
import 'package:flutter/foundation.dart';

class UserStatsController extends ChangeNotifier {
  UserStatsController(this._uid);

  final String _uid;
  final _repo = UserStatsRepository.instance;

  UserStats _stats  = const UserStats();
  bool _loading     = true;
  bool _hasError    = false;

  UserStats get stats    => _stats;
  bool      get loading  => _loading;
  bool      get hasError => _hasError;

  Future<void> load() async {
    _loading  = true;
    _hasError = false;
    notifyListeners();

    try {
      _stats = await _repo.fetchStats(_uid);
    } catch (e) {
      _hasError = true;
      debugPrint('[UserStatsController] load error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load();
}