import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/features/donation/data/service/donation_service.dart';
import 'package:empatia/features/donation/data/model/donation_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // XFile

enum DonationSaveState { idle, loading, success, error }

/// 🎁 DONATION CONTROLLER
///
/// Usa [XFile] em vez de [File] para funcionar no web e no mobile.
class DonationController extends ChangeNotifier {
  final DonationService _service;

  DonationController(this._service);

  DonationSaveState _state = DonationSaveState.idle;
  String? _errorMessage;

  DonationSaveState get state => _state;
  String? get errorMessage => _errorMessage;

  void resetState() {
    _state = DonationSaveState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  Stream<List<DonationModel>> watchMyDonations() =>
      _service.watchMyDonations();

  Stream<List<DonationModel>> watchDonationsByCity(String city) =>
      _service.watchDonationsByCity(city);

  Future<bool> createDonation({
    required String? title,
    required String? category,
    required String? description,
    required XFile photo,
    required UserModel currentUser,
    String? emoji,
  }) async {
    _state = DonationSaveState.loading;
    notifyListeners();

    try {
      await _service.createDonation(
        title: title,
        category: category,
        description: description,
        photo: photo,
        currentUser: currentUser,
        emoji: emoji,
      );
      _state = DonationSaveState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = DonationSaveState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDonation({
    required String donationId,
    required String? title,
    required String? category,
    required String? description,
    required String? currentPhotoUrl,
    XFile? newPhoto,
    String? emoji,
  }) async {
    _state = DonationSaveState.loading;
    notifyListeners();

    try {
      await _service.updateDonation(
        donationId: donationId,
        title: title,
        category: category,
        description: description,
        currentPhotoUrl: currentPhotoUrl,
        newPhoto: newPhoto,
        emoji: emoji,
      );
      _state = DonationSaveState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = DonationSaveState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> updateStatus(String donationId, String newStatus) async {
    try {
      await _service.updateStatus(donationId, newStatus);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> deleteDonation(String donationId, {String? photoUrl}) async {
    try {
      await _service.deleteDonation(donationId, photoUrl: photoUrl);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}