class ServiceModel {
  final String id;
  final String walkerId;
  String type;
  double price;
  String? description;
  String? imageUrl;
  bool isActive;
  final DateTime createdAt;
  DateTime updatedAt;

  ServiceModel({
    required this.id,
    required this.walkerId,
    required this.type,
    required this.price,
    this.description,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'] as String,
      walkerId: map['walker_id'] as String,
      type: map['type'] as String,
      price: (map['price'] as num).toDouble(),
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'walker_id': walkerId,
      'type': type,
      'price': price,
      'description': description,
      'image_url': imageUrl,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  String get typeLabel {
    switch (type) {
      case 'paseo':
        return 'Paseo';
      case 'cuidado':
        return 'Cuidado';
      case 'baño':
        return 'Baño';
      default:
        return type;
    }
  }

  String get typeEmoji {
    switch (type) {
      case 'paseo':
        return '🦮';
      case 'cuidado':
        return '🏠';
      case 'baño':
        return '🛁';
      default:
        return '🐾';
    }
  }
}
