class ChildModel {
  final String? id;
  final String? name;
  final int? age;
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

  ChildModel copyWith({String? id, String? name, int? age, String? emoji}) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      emoji: emoji ?? this.emoji,
    );
  }
}

