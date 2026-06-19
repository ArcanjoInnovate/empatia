import 'package:empatia/features/auth/data/models/birth_model.dart';
import 'package:empatia/features/auth/data/repositories/birth_repository.dart';
import 'package:flutter/foundation.dart';

enum BirthControllerStatus { idle, loading, success, error }

class BirthController extends ChangeNotifier {
  final BirthDateRepository _repository;

  BirthController({BirthDateRepository? repository})
      : _repository = repository ?? BirthDateRepository();

  // ─── STATE ──────────────────────────────────────────────────────────────────

  BirthControllerStatus _status = BirthControllerStatus.idle;
  BirthControllerStatus get status => _status;

  BirthDateModel? _birthDateModel;
  BirthDateModel? get birthDateModel => _birthDateModel;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Convenience getters
  bool get isLoading => _status == BirthControllerStatus.loading;
  bool get isSuccess => _status == BirthControllerStatus.success;
  bool get hasError => _status == BirthControllerStatus.error;
  bool get isVerified => _birthDateModel?.isVerified ?? false;

  // ─── SELECTED DATE (UI state before saving) ─────────────────────────────────

  DateTime? _selectedDate;
  DateTime? get selectedDate => _selectedDate;

  BirthDateValidation? _liveValidation;
  BirthDateValidation? get liveValidation => _liveValidation;

  /// Called when the user picks a date in the UI — validates immediately
  void onDateSelected(DateTime date) {
    _selectedDate = date;
    _liveValidation = _repository.validateBirthDate(date);
    _errorMessage = _liveValidation!.isValid ? null : _liveValidation!.errorMessage;
    notifyListeners();
  }

  /// Clears the selected date and any live validation feedback
  void clearSelectedDate() {
    _selectedDate = null;
    _liveValidation = null;
    _errorMessage = null;
    notifyListeners();
  }

  // ─── ACTIONS ────────────────────────────────────────────────────────────────

  /// Loads the existing birth date for [userId] from Firebase.
  /// Silent — does not throw; on error simply leaves model as null.
  Future<void> loadBirthDate(String userId) async {
    _setStatus(BirthControllerStatus.loading);
    try {
      _birthDateModel = await _repository.getBirthDate(userId);
      _setStatus(BirthControllerStatus.idle);
    } catch (_) {
      _birthDateModel = null;
      _setStatus(BirthControllerStatus.idle);
    }
  }

  /// Validates [birthDate] and, if valid, saves it to Firebase for [userId].
  ///
  /// Returns `true` on success, `false` on validation or network error.
  Future<bool> saveBirthDate({
    required String userId,
    required DateTime birthDate,
  }) async {
    _setStatus(BirthControllerStatus.loading);
    _errorMessage = null;

    final result = await _repository.validateAndSaveBirthDate(
      userId: userId,
      birthDate: birthDate,
    );

    if (result.success) {
      _birthDateModel = result.data;
      _selectedDate = null;
      _liveValidation = null;
      _setStatus(BirthControllerStatus.success);
      return true;
    } else {
      _errorMessage = result.errorMessage;
      _setStatus(BirthControllerStatus.error);
      return false;
    }
  }

  /// Resets the controller back to idle — e.g. to retry after an error.
  void reset() {
    _status = BirthControllerStatus.idle;
    _errorMessage = null;
    _selectedDate = null;
    _liveValidation = null;
    notifyListeners();
  }

  // ─── PRIVATE ────────────────────────────────────────────────────────────────

  void _setStatus(BirthControllerStatus s) {
    _status = s;
    notifyListeners();
  }
}