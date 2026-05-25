/// 🏙️ CIDADE MODEL
/// 
/// É como uma caixa que guarda informações sobre uma cidade.
/// Imagine um fichário com nome e código da cidade.
class CityModel {
  final int id;        // Código da cidade (ex: 5208707)
  final String nome;   // Nome da cidade (ex: "Goiânia")
  
  CityModel({
    required this.id,
    required this.nome,
  });

  /// Transforma dados da internet (JSON) em um objeto Cidade
  /// É como pegar um bilhete escrito e colocar numa caixa organizada
  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'] as int,
      nome: json['nome'] as String,
    );
  }

  /// Transforma a caixa de volta em bilhete (JSON)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}