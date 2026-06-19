import 'package:empatia/features/request/data/model/request_model.dart';
import 'package:empatia/core/data/models/user_model.dart';
import 'package:empatia/features/request/data/repository/request_repository.dart';

/// 🙏 REQUEST SERVICE
///
/// Valida dados e orquestra criação/edição de pedidos de doação.
class RequestService {
  final RequestRepository _repository;

  RequestService(this._repository);

  Stream<List<RequestModel>> watchMyRequests() =>
      _repository.watchMyRequests();

  Stream<List<RequestModel>> watchRequestsByCity(String city) =>
      _repository.watchRequestsByCity(city);

  /// Cria um pedido de doação COM VALIDAÇÃO
  Future<String> createRequest({
    required String? title,
    required String? category,
    required String emoji,
    required UserModel currentUser,
    String? description,
    String? childId,
  }) async {
    // VALIDAÇÃO: título
    final trimmedTitle = title?.trim() ?? '';
    if (trimmedTitle.isEmpty) {
      throw Exception('❌ O título não pode ficar em branco.');
    }
    if (trimmedTitle.length < 3) {
      throw Exception('❌ O título precisa ter pelo menos 3 caracteres.');
    }

    // VALIDAÇÃO: categoria
    final validCategories = [
      'clothes', 'toys', 'books', 'food', 'furniture', 'other'
    ];
    if (category == null || !validCategories.contains(category)) {
      throw Exception('❌ Selecione uma categoria válida.');
    }

    // VALIDAÇÃO: usuário precisa ter localização
    if (currentUser.city == null || currentUser.state == null) {
      throw Exception(
          '❌ Complete sua localização no perfil antes de fazer um pedido.');
    }

    final request = RequestModel(
      title: trimmedTitle,
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      emoji: emoji,
      category: category,
      status: 'open',
      childId: childId,
      // Copia localização do perfil do usuário
      city: currentUser.city,
      state: currentUser.state,
      latitude: currentUser.latitude,
      longitude: currentUser.longitude,
      createdAt: DateTime.now(),
    );

    return await _repository.createRequest(request);
  }

  /// Edita um pedido existente
  Future<void> updateRequest({
    required String requestId,
    required String? title,
    required String? category,
    required String emoji,
    String? description,
    String? childId,
  }) async {
    final trimmedTitle = title?.trim() ?? '';
    if (trimmedTitle.isEmpty) {
      throw Exception('❌ O título não pode ficar em branco.');
    }

    final request = RequestModel(
      id: requestId,
      title: trimmedTitle,
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      emoji: emoji,
      category: category,
      childId: childId,
    );

    await _repository.updateRequest(request);
  }

  /// Altera o status de um pedido
  Future<void> updateStatus(String requestId, String newStatus) async {
    final valid = ['open', 'fulfilled', 'cancelled'];
    if (!valid.contains(newStatus)) {
      throw Exception('❌ Status inválido: $newStatus');
    }
    await _repository.updateStatus(requestId, newStatus);
  }

  /// Remove um pedido
  Future<void> deleteRequest(String requestId) async {
    await _repository.deleteRequest(requestId);
  }
}