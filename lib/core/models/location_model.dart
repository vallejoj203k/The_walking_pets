import 'dart:math';

class WalkerLocationModel {
  final String walkerId;
  final double latitude;
  final double longitude;
  final bool isSharing;
  final DateTime lastUpdated;

  WalkerLocationModel({
    required this.walkerId,
    required this.latitude,
    required this.longitude,
    required this.isSharing,
    required this.lastUpdated,
  });

  factory WalkerLocationModel.fromMap(Map<String, dynamic> map) {
    return WalkerLocationModel(
      walkerId: map['walker_id'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      isSharing: map['is_sharing'] as bool? ?? false,
      lastUpdated: DateTime.parse(map['last_updated'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'walker_id': walkerId,
      'latitude': latitude,
      'longitude': longitude,
      'is_sharing': isSharing,
      'last_updated': DateTime.now().toIso8601String(),
    };
  }

  // Calcular distancia en km usando la fórmula de Haversine
  double distanceTo(double lat, double lng) {
    const R = 6371.0;
    final dLat = _toRad(lat - latitude);
    final dLng = _toRad(lng - longitude);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(latitude)) * cos(_toRad(lat)) *
            sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;
}
