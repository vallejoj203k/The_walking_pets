import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/booking_model.dart';

class BookingProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<BookingModel> _ownerBookings = [];
  List<BookingModel> _walkerBookings = [];
  bool _isLoading = false;
  String? _error;

  List<BookingModel> get ownerBookings => List.unmodifiable(_ownerBookings);
  List<BookingModel> get walkerBookings => List.unmodifiable(_walkerBookings);
  List<BookingModel> get pendingRequests =>
      _walkerBookings.where((b) => b.status == 'pending').toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadOwnerBookings(String userId) async {
    _setLoading(true);
    try {
      final ownerData = await SupabaseService.client
          .from('owners')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (ownerData == null) {
        _ownerBookings = [];
        _setLoading(false);
        return;
      }
      final ownerId = ownerData['id'] as String;
      final data = await SupabaseService.client
          .from('bookings')
          .select()
          .eq('owner_id', ownerId)
          .order('scheduled_date', ascending: false);
      _ownerBookings =
          (data as List).map((e) => BookingModel.fromMap(e)).toList();
      await _enrichBookings(_ownerBookings);
      _error = null;
    } catch (e) {
      _error = 'Error al cargar reservas.';
      debugPrint('[BookingProvider] loadOwnerBookings: $e');
    }
    _setLoading(false);
  }

  Future<void> loadWalkerBookings(String userId) async {
    _setLoading(true);
    try {
      final walkerData = await SupabaseService.client
          .from('walkers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();
      if (walkerData == null) {
        _walkerBookings = [];
        _setLoading(false);
        return;
      }
      final walkerId = walkerData['id'] as String;
      final data = await SupabaseService.client
          .from('bookings')
          .select()
          .eq('walker_id', walkerId)
          .order('scheduled_date', ascending: false);
      _walkerBookings =
          (data as List).map((e) => BookingModel.fromMap(e)).toList();
      await _enrichBookings(_walkerBookings);
      _error = null;
    } catch (e) {
      _error = 'Error al cargar solicitudes.';
      debugPrint('[BookingProvider] loadWalkerBookings: $e');
    }
    _setLoading(false);
  }

  Future<void> _enrichBookings(List<BookingModel> bookings) async {
    for (final b in bookings) {
      try {
        // Walker name + user_id
        final walkerData = await SupabaseService.client
            .from('walkers')
            .select('name, user_id')
            .eq('id', b.walkerId)
            .maybeSingle();
        b.walkerName = walkerData?['name'] as String?;
        b.walkerUserId = walkerData?['user_id'] as String?;

        // Owner name + user_id
        final ownerData = await SupabaseService.client
            .from('owners')
            .select('name, user_id')
            .eq('id', b.ownerId)
            .maybeSingle();
        b.ownerName = ownerData?['name'] as String?;
        b.ownerUserId = ownerData?['user_id'] as String?;

        // Pet name
        final petData = await SupabaseService.client
            .from('pets')
            .select('name')
            .eq('id', b.petId)
            .maybeSingle();
        b.petName = petData?['name'] as String?;

        // Service info
        if (b.serviceId != null) {
          final serviceData = await SupabaseService.client
              .from('services')
              .select('type, price')
              .eq('id', b.serviceId!)
              .maybeSingle();
          b.serviceType = serviceData?['type'] as String?;
          b.servicePrice = serviceData?['price'] != null
              ? (serviceData!['price'] as num).toDouble()
              : null;
        }
      } catch (e) {
        debugPrint('[BookingProvider] enrich error: $e');
      }
    }
  }

  Future<bool> createBooking({
    required String walkerId,
    required String ownerId,
    required String serviceId,
    required String petId,
    List<String>? petIds,
    double? totalAmount,
    required DateTime scheduledDate,
    String? notes,
  }) async {
    _setLoading(true);
    try {
      final id = _uuid.v4();
      final now = DateTime.now().toIso8601String();
      final allPetIds = petIds ?? [petId];
      final data = {
        'id': id,
        'walker_id': walkerId,
        'owner_id': ownerId,
        'service_id': serviceId,
        'pet_id': petId,
        'pet_ids': allPetIds,
        'total_amount': totalAmount,
        'status': 'pending',
        'scheduled_date': scheduledDate.toUtc().toIso8601String(),
        'notes': notes,
        'created_at': now,
        'updated_at': now,
      };
      await SupabaseService.client.from('bookings').insert(data);
      _error = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = 'Error al crear la reserva.';
      debugPrint('[BookingProvider] createBooking: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateBookingStatus(String bookingId, String status) async {
    try {
      await SupabaseService.client.from('bookings').update({
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);

      for (final list in [_ownerBookings, _walkerBookings]) {
        final idx = list.indexWhere((b) => b.id == bookingId);
        if (idx != -1) list[idx].status = status;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[BookingProvider] updateStatus: $e');
      return false;
    }
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
