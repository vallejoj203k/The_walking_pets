import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/walker_model.dart';
import '../../../core/models/owner_model.dart';
import '../../../core/models/pet_model.dart';
import '../../../config/constants/app_constants.dart';

class ProfileProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final _uuid = const Uuid();

  WalkerModel? _walker;
  OwnerModel? _owner;
  List<PetModel> _pets = [];
  bool _isLoading = false;
  String? _error;

  WalkerModel? get walker => _walker;
  OwnerModel? get owner => _owner;
  List<PetModel> get pets => List.unmodifiable(_pets);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadWalkerProfile(String userId) async {
    _setLoading(true);
    try {
      final data = await SupabaseService.client
          .from('walkers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      _walker = data != null ? WalkerModel.fromMap(data) : null;
      _error = null;
    } catch (e) {
      _error = 'Error al cargar perfil de paseador.';
    }
    _setLoading(false);
  }

  Future<void> loadOwnerProfile(String userId) async {
    _setLoading(true);
    try {
      final data = await SupabaseService.client
          .from('owners')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      _owner = data != null ? OwnerModel.fromMap(data) : null;
      if (_owner != null) {
        await _loadPets(_owner!.id);
      }
      _error = null;
    } catch (e) {
      _error = 'Error al cargar perfil de dueño.';
    }
    _setLoading(false);
  }

  Future<void> _loadPets(String ownerId) async {
    final data = await SupabaseService.client
        .from('pets')
        .select()
        .eq('owner_id', ownerId)
        .order('created_at');
    _pets = (data as List).map((e) => PetModel.fromMap(e)).toList();
  }

  Future<bool> saveWalkerProfile({
    required String userId,
    required String name,
    required List<String> services,
    int? experienceYears,
    double? hourlyRate,
    String? coverageZone,
    File? photoFile,
  }) async {
    _setLoading(true);
    try {
      String? photoUrl = _walker?.photoUrl;

      if (photoFile != null) {
        photoUrl = await _storageService.uploadAvatar(
          file: photoFile,
          storagePath: AppConstants.walkerAvatarPath(userId),
        );
      }

      if (_walker == null) {
        // Create
        final id = _uuid.v4();
        final data = {
          'id': id,
          'user_id': userId,
          'name': name,
          'photo_url': photoUrl,
          'experience_years': experienceYears,
          'services': services,
          'hourly_rate': hourlyRate,
          'coverage_zone': coverageZone,
          'verified': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        await SupabaseService.client.from('walkers').insert(data);
        final result = await SupabaseService.client
            .from('walkers')
            .select()
            .eq('id', id)
            .single();
        _walker = WalkerModel.fromMap(result);
      } else {
        // Update
        final data = {
          'name': name,
          'photo_url': photoUrl,
          'experience_years': experienceYears,
          'services': services,
          'hourly_rate': hourlyRate,
          'coverage_zone': coverageZone,
          'updated_at': DateTime.now().toIso8601String(),
        };
        await SupabaseService.client
            .from('walkers')
            .update(data)
            .eq('id', _walker!.id);
        _walker!.name = name;
        _walker!.photoUrl = photoUrl;
        _walker!.experienceYears = experienceYears;
        _walker!.services = services;
        _walker!.hourlyRate = hourlyRate;
        _walker!.coverageZone = coverageZone;
      }

      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Error al guardar perfil. Intenta de nuevo.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> saveOwnerProfile({
    required String userId,
    required String name,
    String? address,
    File? photoFile,
  }) async {
    _setLoading(true);
    try {
      String? photoUrl = _owner?.photoUrl;

      if (photoFile != null) {
        photoUrl = await _storageService.uploadAvatar(
          file: photoFile,
          storagePath: AppConstants.ownerAvatarPath(userId),
        );
      }

      if (_owner == null) {
        final id = _uuid.v4();
        final data = {
          'id': id,
          'user_id': userId,
          'name': name,
          'photo_url': photoUrl,
          'address': address,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        await SupabaseService.client.from('owners').insert(data);
        final result = await SupabaseService.client
            .from('owners')
            .select()
            .eq('id', id)
            .single();
        _owner = OwnerModel.fromMap(result);
      } else {
        await SupabaseService.client.from('owners').update({
          'name': name,
          'photo_url': photoUrl,
          'address': address,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', _owner!.id);
        _owner!.name = name;
        _owner!.photoUrl = photoUrl;
        _owner!.address = address;
      }

      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Error al guardar perfil. Intenta de nuevo.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> saveHomeLocation({
    required String walkerId,
    required double lat,
    required double lng,
  }) async {
    try {
      await SupabaseService.client.from('walkers').update({
        'home_lat': lat,
        'home_lng': lng,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', walkerId);
      if (_walker != null) {
        _walker!.homeLat = lat;
        _walker!.homeLng = lng;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Error al guardar ubicación.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> addPet({
    required String name,
    required String type,
    required String size,
  }) async {
    if (_owner == null) return false;
    _setLoading(true);
    try {
      final id = _uuid.v4();
      final data = {
        'id': id,
        'owner_id': _owner!.id,
        'name': name,
        'type': type,
        'size': size,
        'created_at': DateTime.now().toIso8601String(),
      };
      await SupabaseService.client.from('pets').insert(data);
      _pets.add(PetModel.fromMap({...data}));
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Error al agregar mascota.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deletePet(String petId) async {
    _setLoading(true);
    try {
      await SupabaseService.client.from('pets').delete().eq('id', petId);
      _pets.removeWhere((p) => p.id == petId);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Error al eliminar mascota.';
      _setLoading(false);
      return false;
    }
  }

  void clear() {
    _walker = null;
    _owner = null;
    _pets = [];
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
