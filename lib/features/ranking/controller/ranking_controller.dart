// lib/features/home/controllers/ranking_controller.dart

import 'package:empatia/features/ranking/data/repository/ranking_repository.dart';
import 'package:flutter/foundation.dart';

enum RankingStatus { idle, loading, loaded, error }

class RankingController extends ChangeNotifier {
  RankingController({this.limit = 100});

  final int limit;
  final _repo = RankingRepository.instance;

  List<RankingEntry> _entries = [];
  RankingStatus      _status  = RankingStatus.idle;
  String?            _error;

  List<RankingEntry> get entries => _entries;
  RankingStatus      get status  => _status;
  String?            get error   => _error;

  bool get isLoading => _status == RankingStatus.loading;
  bool get isLoaded  => _status == RankingStatus.loaded;
  bool get hasError  => _status == RankingStatus.error;
  bool get isEmpty   => isLoaded && _entries.isEmpty;

  /// Dias corridos até o próximo reset de segunda-feira às 00h00.
  /// Calculado localmente — sem custo de rede.
  /// Retorna 0 no próprio dia do reset (domingo).
  int get daysUntilReset {
    final now     = DateTime.now();
    // weekday: Mon=1 … Sun=7
    // Dias restantes até domingo (fim da semana ISO)
    final daysLeft = 7 - now.weekday; // Dom=7 → 0, Sáb=6 → 1, …
    return daysLeft;
  }

  Future<void> load() async {
    _status = RankingStatus.loading;
    _error  = null;
    notifyListeners();

    try {
      _entries = await _repo.fetchTopDonors(limit: limit);
      _status  = RankingStatus.loaded;
    } catch (e) {
      _error  = e.toString();
      _status = RankingStatus.error;
      debugPrint('[RankingController] load error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<void> refresh() => load();
}