class WalkerModel {
  final String id;
  final String userId;
  String name;
  String? photoUrl;
  int? experienceYears;
  List<String> services;
  double? hourlyRate;
  String? coverageZone;
  double? homeLat;
  double? homeLng;
  bool verified;
  final DateTime createdAt;
  DateTime updatedAt;

  WalkerModel({
    required this.id,
    required this.userId,
    required this.name,
    this.photoUrl,
    this.experienceYears,
    this.services = const [],
    this.hourlyRate,
    this.coverageZone,
    this.homeLat,
    this.homeLng,
    this.verified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get hasHomeLocation => homeLat != null && homeLng != null;

  factory WalkerModel.fromMap(Map<String, dynamic> map) {
    List<String> services = [];
    if (map['services'] != null) {
      services = List<String>.from(map['services'] as List);
    }
    return WalkerModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      photoUrl: map['photo_url'] as String?,
      experienceYears: map['experience_years'] as int?,
      services: services,
      hourlyRate: map['hourly_rate'] != null
          ? (map['hourly_rate'] as num).toDouble()
          : null,
      coverageZone: map['coverage_zone'] as String?,
      homeLat: map['home_lat'] != null ? (map['home_lat'] as num).toDouble() : null,
      homeLng: map['home_lng'] != null ? (map['home_lng'] as num).toDouble() : null,
      verified: map['verified'] as bool? ?? false,
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
      'experience_years': experienceYears,
      'services': services,
      'hourly_rate': hourlyRate,
      'coverage_zone': coverageZone,
      'home_lat': homeLat,
      'home_lng': homeLng,
      'verified': verified,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
