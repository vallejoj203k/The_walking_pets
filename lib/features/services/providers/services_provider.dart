import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/service_model.dart';

class ServicesProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<ServiceModel> _myServices = [];
  List<ServiceModel> _walkerServices = [];
  bool _isLoading = false;
  String? _error;

  List<ServiceModel> get myServices => List.unmodifiable(_myServices);
  List<ServiceModel> get walkerServices => List.unmodifiable(_walkerServices);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMyServices(String walkerId) async {
    _setLoading(true);
    try {
      final data = await SupabaseService.client
          .from('services')
          .select()
          .eq('walker_id', walkerId)
          .order('created_at');
      _myServices =
          (data as List).map((e) => ServiceModel.fromMap(e)).toList();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar servicios.';
      debugPrint('[ServicesProvider] loadMyServices: $e');
    }
    _setLoading(false);
  }

  // Carga servicios usando el user_id del paseador (busca el walker primero)
  Future<void> loadMyServicesByUserId(String userId) async {
    _setLoading(true);
    try {
      final walkerData = await SupabaseService.client
          .from('walkers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (walkerData == null) {
        _myServices = [];
        _setLoading(false);
        return;
      }
      final walkerId = walkerData['id'] as String;
      await loadMyServices(walkerId);
    } catch (e) {
      _error = 'Error al cargar servicios.';
      debugPrint('[ServicesProvider] loadMyServicesByUserId: $e');
      _setLoading(false);
    }
  }

  // Búsqueda de paseadores con sus servicios para el dueño
  Future<List<Map<String, dynamic>>> searchWalkers({
    String? serviceType,
    double? maxPrice,
  }) async {
    try {
      var query = SupabaseService.client
          .from('services')
          .select('*, walkers(id, user_id, name, photo_url, experience_years, coverage_zone, hourly_rate)')
          .eq('is_active', true);

      if (serviceType != null) {
        query = query.eq('type', serviceType);
      }
      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }

      final data = await query.order('price');
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('[ServicesProvider] searchWalkers: $e');
      return [];
    }
  }

  Future<void> loadWalkerServices(String walkerId) async {
    _setLoading(true);
    try {
      final data = await SupabaseService.client
          .from('services')
          .select()
          .eq('walker_id', walkerId)
          .eq('is_active', true)
          .order('created_at');
      _walkerServices =
          (data as List).map((e) => ServiceModel.fromMap(e)).toList();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar servicios del paseador.';
    }
    _setLoading(false);
  }

  Future<bool> createService({
    required String walkerId,
    required String type,
    required double price,
    String? description,
  }) async {
    _setLoading(true);
    try {
      final id = _uuid.v4();
      final now = DateTime.now().toIso8601String();
      final data = {
        'id': id,
        'walker_id': walkerId,
        'type': type,
        'price': price,
        'description': description,
        'is_active': true,
        'created_at': now,
        'updated_at': now,
      };
      await SupabaseService.client.from('services').insert(data);
      _myServices.add(ServiceModel.fromMap({...data}));
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Error al crear servicio.';
      debugPrint('[ServicesProvider] createService: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateService({
    required String serviceId,
    required String type,
    required double price,
    String? description,
  }) async {
    _setLoading(true);
    try {
      final data = {
        'type': type,
        'price': price,
        'description': description,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await SupabaseService.client
          .from('services')
          .update(data)
          .eq('id', serviceId);

      final idx = _myServices.indexWhere((s) => s.id == serviceId);
      if (idx != -1) {
        _myServices[idx].type = type;
        _myServices[idx].price = price;
        _myServices[idx].description = description;
      }
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Error al actualizar servicio.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> toggleServiceActive(String serviceId, bool isActive) async {
    try {
      await SupabaseService.client
          .from('services')
          .update({'is_active': isActive, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', serviceId);
      final idx = _myServices.indexWhere((s) => s.id == serviceId);
      if (idx != -1) _myServices[idx].isActive = isActive;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[ServicesProvider] toggleActive: $e');
      return false;
    }
  }

  Future<bool> deleteService(String serviceId) async {
    _setLoading(true);
    try {
      await SupabaseService.client
          .from('services')
          .delete()
          .eq('id', serviceId);
      _myServices.removeWhere((s) => s.id == serviceId);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Error al eliminar servicio.';
      _setLoading(false);
      return false;
    }
  }

  Future<String?> getWalkerIdByUserId(String userId) async {
    try {
      final data = await SupabaseService.client
          .from('walkers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      return data?['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
