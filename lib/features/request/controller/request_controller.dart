import 'package:empatia/features/request/data/model/request_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/features/request/data/service/request_service.dart';
import 'package:flutter/material.dart';

enum RequestSaveState { idle, loading, success, error }

/// 🙏 REQUEST CONTROLLER
///
/// Gerencia estado de UI para criação/edição/remoção de pedidos.
class RequestController extends ChangeNotifier {
  final RequestService _service;

  RequestController(this._service);

  RequestSaveState _state = RequestSaveState.idle;
  String? _errorMessage;

  RequestSaveState get state => _state;
  String? get errorMessage => _errorMessage;

  void resetState() {
    _state = RequestSaveState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Stream dos pedidos do usuário logado (para o perfil)
  Stream<List<RequestModel>> watchMyRequests() =>
      _service.watchMyRequests();

  /// Stream de pedidos abertos em uma cidade (para o feed)
  Stream<List<RequestModel>> watchRequestsByCity(String city) =>
      _service.watchRequestsByCity(city);

  /// Cria um novo pedido
  Future<bool> createRequest({
    required String? title,
    required String? category,
    required String emoji,
    required UserModel currentUser,
    String? description,
    String? childId,
  }) async {
    _state = RequestSaveState.loading;
    notifyListeners();

    try {
      await _service.createRequest(
        title: title,
        category: category,
        emoji: emoji,
        currentUser: currentUser,
        description: description,
        childId: childId,
      );
      _state = RequestSaveState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = RequestSaveState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Edita um pedido
  Future<bool> updateRequest({
    required String requestId,
    required String? title,
    required String? category,
    required String emoji,
    String? description,
    String? childId,
  }) async {
    _state = RequestSaveState.loading;
    notifyListeners();

    try {
      await _service.updateRequest(
        requestId: requestId,
        title: title,
        category: category,
        emoji: emoji,
        description: description,
        childId: childId,
      );
      _state = RequestSaveState.success;
      notifyListeners();
      return true;
    } catch (e) {
      _state = RequestSaveState.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Marca como atendido / cancelado / aberto
  Future<void> updateStatus(String requestId, String newStatus) async {
    try {
      await _service.updateStatus(requestId, newStatus);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  /// Remove um pedido
  Future<void> deleteRequest(String requestId) async {
    try {
      await _service.deleteRequest(requestId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}