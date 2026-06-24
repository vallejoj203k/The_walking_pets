import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';

class AdminProvider extends ChangeNotifier {
  bool _isAdmin = false;
  String? _adminRole;
  bool _checked = false;

  bool get isAdmin => _isAdmin;
  String? get adminRole => _adminRole;
  bool get isSuperAdmin => _adminRole == 'super_admin';
  bool get checked => _checked;

  Future<bool> checkAdminStatus(String userId) async {
    try {
      final data = await SupabaseService.client
          .from('users')
          .select('is_admin')
          .eq('id', userId)
          .maybeSingle();

      _isAdmin = (data?['is_admin'] as bool?) == true;
      _adminRole = _isAdmin ? 'super_admin' : null;
    } catch (e) {
      _isAdmin = false;
      _adminRole = null;
      debugPrint('[AdminProvider] checkAdminStatus: $e');
    }
    _checked = true;
    notifyListeners();
    return _isAdmin;
  }

  void reset() {
    _isAdmin = false;
    _adminRole = null;
    _checked = false;
    notifyListeners();
  }

  // ── Analytics ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final results = await Future.wait([
        SupabaseService.client.from('walkers').select('id'),
        SupabaseService.client.from('owners').select('id'),
        SupabaseService.client.from('bookings').select('id, status, created_at'),
        SupabaseService.client
            .from('transactions')
            .select('amount, status')
            .eq('status', 'approved'),
        SupabaseService.client.from('reviews').select('rating'),
        SupabaseService.client
            .from('support_tickets')
            .select('id, status')
            .eq('status', 'open'),
      ]);

      final walkers = (results[0] as List).length;
      final owners = (results[1] as List).length;
      final bookings = results[2] as List;
      final transactions = results[3] as List;
      final reviews = results[4] as List;
      final openTickets = (results[5] as List).length;

      final completed =
          bookings.where((b) => b['status'] == 'completed').length;
      final totalRevenue = transactions.fold<double>(
          0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));
      final avgRating = reviews.isEmpty
          ? 0.0
          : reviews.fold<double>(
                  0, (s, r) => s + ((r['rating'] as num?)?.toDouble() ?? 0)) /
              reviews.length;

      // Bookings by month (last 6)
      final now = DateTime.now();
      final monthlyBookings = <String, int>{};
      for (var i = 5; i >= 0; i--) {
        final m = DateTime(now.year, now.month - i, 1);
        final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
        monthlyBookings[key] = 0;
      }
      for (final b in bookings) {
        final dt = DateTime.parse(b['created_at'] as String);
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        if (monthlyBookings.containsKey(key)) {
          monthlyBookings[key] = (monthlyBookings[key] ?? 0) + 1;
        }
      }

      return {
        'walkers': walkers,
        'owners': owners,
        'totalUsers': walkers + owners,
        'totalBookings': bookings.length,
        'completedBookings': completed,
        'totalRevenue': totalRevenue,
        'totalFees': totalRevenue * 0.10,
        'avgRating': avgRating,
        'openTickets': openTickets,
        'monthlyBookings': monthlyBookings,
      };
    } catch (e) {
      debugPrint('[AdminProvider] getDashboardStats: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final walkers = await SupabaseService.client
          .from('walkers')
          .select('id, name, user_id, coverage_zone, created_at')
          .order('created_at', ascending: false);
      final owners = await SupabaseService.client
          .from('owners')
          .select('id, name, user_id, city, created_at')
          .order('created_at', ascending: false);

      final result = <Map<String, dynamic>>[];
      for (final w in walkers as List) {
        result.add({...w, 'type': 'walker'});
      }
      for (final o in owners as List) {
        result.add({...o, 'type': 'owner'});
      }
      result.sort((a, b) {
        final aDate = DateTime.parse(a['created_at'] as String);
        final bDate = DateTime.parse(b['created_at'] as String);
        return bDate.compareTo(aDate);
      });
      return result;
    } catch (e) {
      debugPrint('[AdminProvider] getAllUsers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    try {
      final data = await SupabaseService.client
          .from('transactions')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('[AdminProvider] getAllTransactions: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getAnalyticsData() async {
    try {
      final results = await Future.wait([
        SupabaseService.client.from('bookings').select('status, created_at'),
        SupabaseService.client
            .from('services')
            .select('type')
            .eq('is_active', true),
        SupabaseService.client
            .from('transactions')
            .select('amount, created_at, status')
            .eq('status', 'approved'),
        SupabaseService.client.from('reviews').select('rating, created_at'),
        SupabaseService.client
            .from('walkers')
            .select('id, name, created_at'),
        SupabaseService.client
            .from('owners')
            .select('id, name, created_at'),
      ]);

      final bookings = results[0] as List;
      final services = results[1] as List;
      final transactions = results[2] as List;
      final reviews = results[3] as List;
      final walkers = results[4] as List;
      final owners = results[5] as List;

      // Service distribution
      final svcDist = <String, int>{'paseo': 0, 'cuidado': 0, 'baño': 0};
      for (final s in services) {
        final t = s['type'] as String? ?? '';
        svcDist[t] = (svcDist[t] ?? 0) + 1;
      }

      // Booking status dist
      final bkDist = <String, int>{};
      for (final b in bookings) {
        final s = b['status'] as String? ?? '';
        bkDist[s] = (bkDist[s] ?? 0) + 1;
      }

      // Monthly revenue (last 6)
      final now = DateTime.now();
      final monthlyRev = <String, double>{};
      for (var i = 5; i >= 0; i--) {
        final m = DateTime(now.year, now.month - i, 1);
        monthlyRev['${m.year}-${m.month.toString().padLeft(2, '0')}'] = 0;
      }
      for (final t in transactions) {
        final dt = DateTime.parse(t['created_at'] as String);
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        if (monthlyRev.containsKey(key)) {
          monthlyRev[key] =
              (monthlyRev[key] ?? 0) + ((t['amount'] as num?)?.toDouble() ?? 0);
        }
      }

      // Monthly registrations walkers+owners (last 6)
      final monthlyUsers = <String, int>{};
      for (var i = 5; i >= 0; i--) {
        final m = DateTime(now.year, now.month - i, 1);
        monthlyUsers['${m.year}-${m.month.toString().padLeft(2, '0')}'] = 0;
      }
      for (final u in [...walkers, ...owners]) {
        final dt = DateTime.parse(u['created_at'] as String);
        final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
        if (monthlyUsers.containsKey(key)) {
          monthlyUsers[key] = (monthlyUsers[key] ?? 0) + 1;
        }
      }

      return {
        'serviceDistribution': svcDist,
        'bookingStatus': bkDist,
        'monthlyRevenue': monthlyRev,
        'monthlyUsers': monthlyUsers,
        'totalWalkers': walkers.length,
        'totalOwners': owners.length,
        'totalReviews': reviews.length,
        'avgRating': reviews.isEmpty
            ? 0.0
            : reviews.fold<double>(0,
                    (s, r) => s + ((r['rating'] as num?)?.toDouble() ?? 0)) /
                reviews.length,
      };
    } catch (e) {
      debugPrint('[AdminProvider] getAnalyticsData: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> getPlatformSettings() async {
    try {
      final data = await SupabaseService.client
          .from('platform_settings')
          .select('key, value, description');
      final map = <String, dynamic>{};
      for (final row in data as List) {
        map[row['key'] as String] = {
          'value': row['value'],
          'description': row['description'],
        };
      }
      return map;
    } catch (e) {
      debugPrint('[AdminProvider] getPlatformSettings: $e');
      return {};
    }
  }

  Future<bool> updatePlatformSetting(String key, String value) async {
    try {
      await SupabaseService.client.from('platform_settings').upsert({
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('[AdminProvider] updatePlatformSetting: $e');
      return false;
    }
  }
}
