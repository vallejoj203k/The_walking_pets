import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/location_service.dart';
import '../../../core/models/location_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../config/constants/maps_config.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  Position? _currentPosition;
  bool _isSharing = false;
  bool _isLoading = false;
  StreamSubscription<Position>? _positionSub;
  Timer? _uploadTimer;
  String? _currentWalkerId;

  Position? get currentPosition => _currentPosition;
  bool get isSharing => _isSharing;
  bool get isLoading => _isLoading;
  double get currentLat =>
      _currentPosition?.latitude ?? MapsConfig.defaultLat;
  double get currentLng =>
      _currentPosition?.longitude ?? MapsConfig.defaultLng;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    final position = await _locationService.getCurrentPosition();
    _currentPosition = position;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> startSharingLocation(String walkerId) async {
    _currentWalkerId = walkerId;
    _isSharing = true;
    notifyListeners();

    _positionSub = _locationService.getPositionStream().listen((pos) {
      _currentPosition = pos;
      notifyListeners();
    });

    // Upload al servidor cada 10 segundos
    _uploadTimer = Timer.periodic(
      const Duration(seconds: MapsConfig.locationUpdateIntervalSeconds),
      (_) => _uploadLocation(),
    );

    await _uploadLocation(sharing: true);
  }

  Future<void> stopSharingLocation() async {
    _positionSub?.cancel();
    _uploadTimer?.cancel();
    _isSharing = false;

    if (_currentWalkerId != null) {
      await _uploadLocation(sharing: false);
    }
    notifyListeners();
  }

  Future<void> _uploadLocation({bool? sharing}) async {
    if (_currentPosition == null && _currentWalkerId == null) return;
    try {
      await SupabaseService.client.from('walker_locations').upsert({
        'walker_id': _currentWalkerId,
        'latitude': _currentPosition?.latitude ?? MapsConfig.defaultLat,
        'longitude': _currentPosition?.longitude ?? MapsConfig.defaultLng,
        'is_sharing': sharing ?? _isSharing,
        'last_updated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[LocationProvider] Upload error: $e');
    }
  }

  Future<List<WalkerLocationModel>> getNearbyWalkers() async {
    try {
      final data = await SupabaseService.client
          .from('walker_locations')
          .select()
          .eq('is_sharing', true);

      final all = (data as List)
          .map((e) => WalkerLocationModel.fromMap(e))
          .toList();

      if (_currentPosition == null) return all;

      return all.where((w) {
        final dist = w.distanceTo(currentLat, currentLng);
        return dist <= MapsConfig.maxSearchRadiusKm;
      }).toList();
    } catch (e) {
      debugPrint('[LocationProvider] getNearbyWalkers error: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> watchWalkerLocation(String walkerId) {
    return SupabaseService.client
        .from('walker_locations')
        .stream(primaryKey: ['walker_id'])
        .eq('walker_id', walkerId);
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _uploadTimer?.cancel();
    super.dispose();
  }
}
