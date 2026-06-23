class OwnerModel {
  final String id;
  final String userId;
  String name;
  String? photoUrl;
  String? address;
  final DateTime createdAt;
  DateTime updatedAt;

  OwnerModel({
    required this.id,
    required this.userId,
    required this.name,
    this.photoUrl,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OwnerModel.fromMap(Map<String, dynamic> map) {
    return OwnerModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      photoUrl: map['photo_url'] as String?,
      address: map['address'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'photo_url': photoUrl,
      'address': address,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
