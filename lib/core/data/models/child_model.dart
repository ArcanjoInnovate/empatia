class ChildModel {
  final String? id;
  final String? name;
  final int? age;

  /// Caminho do asset de avatar (ex: "assets/children/girl/3.webp").
  /// Mantém o nome `emoji` por compatibilidade com o banco já existente,
  /// mas o valor agora é um caminho de imagem, não mais um emoji.
  final String? emoji;

  const ChildModel({this.id, this.name, this.age, this.emoji});

  factory ChildModel.fromMap(Map<dynamic, dynamic> map, String id) {
    return ChildModel(
      id: id,
      name: map['name']?.toString(),
      age: map['age'] != null ? int.tryParse(map['age'].toString()) : null,
      emoji: map['emoji']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (name != null) 'name': name,
      if (age != null) 'age': age,
      if (emoji != null) 'emoji': emoji,
    };
  }

  /// Deriva o gênero do avatar a partir do caminho do asset salvo,
  /// usado para abrir o seletor já no grupo correto ao editar.
  String get genero => (emoji ?? '').contains('/girl/') ? 'menina' : 'menino';

  ChildModel copyWith({String? id, String? name, int? age, String? emoji}) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      emoji: emoji ?? this.emoji,
    );
  }
}