class PetModel {
  final String id;
  final String ownerId;
  String name;
  String type;
  String size;
  final DateTime createdAt;

  PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.size,
    required this.createdAt,
  });

  factory PetModel.fromMap(Map<String, dynamic> map) {
    return PetModel(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      size: map['size'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'type': type,
      'size': size,
    };
  }

  String get typeEmoji {
    switch (type) {
      case 'perro':
        return '🐶';
      case 'gato':
        return '🐱';
      default:
        return '🐾';
    }
  }
}
