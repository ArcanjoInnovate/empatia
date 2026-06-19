import 'package:empatia/features/auth/data/models/birth_model.dart';
import 'package:firebase_database/firebase_database.dart';

class BirthDateService {
  final FirebaseDatabase _database;
  
  BirthDateService({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  // Referência base para os usuários
  DatabaseReference _getUserRef(String userId) {
    return _database.ref('Users/$userId');
  }

  /// Salva a data de nascimento e idade do usuário
  /// 
  /// Parâmetros:
  /// - [userId]: ID do usuário autenticado
  /// - [birthDateModel]: Model com os dados de nascimento
  /// 
  /// Retorna: Future<void>
  /// Throws: Exception se houver erro ao salvar
  Future<void> saveBirthDate({
    required String userId,
    required BirthDateModel birthDateModel,
  }) async {
    try {
      final userRef = _getUserRef(userId);
      
      // Prepara os dados para salvar
      final Map<String, dynamic> updates = {
        'birthDate': birthDateModel.birthDate.millisecondsSinceEpoch,
        'age': birthDateModel.age,
        'birthDateVerified': birthDateModel.isVerified,
        'birthDateVerifiedAt': birthDateModel.verifiedAt?.millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Salva no Firebase
      await userRef.update(updates);
    } catch (e) {
      throw Exception('Erro ao salvar data de nascimento: $e');
    }
  }

  /// Busca os dados de nascimento do usuário
  /// 
  /// Parâmetros:
  /// - [userId]: ID do usuário
  /// 
  /// Retorna: BirthDateModel ou null se não encontrado
  Future<BirthDateModel?> getBirthDate(String userId) async {
    try {
      final userRef = _getUserRef(userId);
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        return null;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      
      // Verifica se tem data de nascimento
      if (data['birthDate'] == null) {
        return null;
      }

      return BirthDateModel(
        birthDate: DateTime.fromMillisecondsSinceEpoch(data['birthDate'] as int),
        age: data['age'] as int,
        isVerified: data['birthDateVerified'] as bool? ?? false,
        verifiedAt: data['birthDateVerifiedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['birthDateVerifiedAt'] as int)
            : null,
      );
    } catch (e) {
      throw Exception('Erro ao buscar data de nascimento: $e');
    }
  }

  /// Verifica se o usuário já tem data de nascimento cadastrada
  Future<bool> hasBirthDate(String userId) async {
    try {
      final birthDate = await getBirthDate(userId);
      return birthDate != null;
    } catch (e) {
      return false;
    }
  }

  /// Marca a data de nascimento como verificada
  Future<void> markAsVerified(String userId) async {
    try {
      final userRef = _getUserRef(userId);
      
      await userRef.update({
        'birthDateVerified': true,
        'birthDateVerifiedAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Erro ao marcar como verificado: $e');
    }
  }

  /// Atualiza a idade do usuário (útil para jobs agendados)
  Future<void> updateAge(String userId) async {
    try {
      final birthDateModel = await getBirthDate(userId);
      
      if (birthDateModel == null) {
        return;
      }

      // Recalcula a idade
      final newAge = _calculateAge(birthDateModel.birthDate);
      
      // Atualiza apenas se a idade mudou
      if (newAge != birthDateModel.age) {
        final userRef = _getUserRef(userId);
        await userRef.update({
          'age': newAge,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
    } catch (e) {
      throw Exception('Erro ao atualizar idade: $e');
    }
  }

  /// Remove a data de nascimento (caso necessário)
  Future<void> removeBirthDate(String userId) async {
    try {
      final userRef = _getUserRef(userId);
      
      await userRef.update({
        'birthDate': null,
        'age': null,
        'birthDateVerified': null,
        'birthDateVerifiedAt': null,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Erro ao remover data de nascimento: $e');
    }
  }

  // Método auxiliar para calcular idade
  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}