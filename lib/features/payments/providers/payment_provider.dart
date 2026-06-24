import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/transaction_model.dart';
import '../../../config/constants/app_constants.dart';

class PaymentProvider extends ChangeNotifier {
  List<TransactionModel> _ownerTransactions = [];
  WalkerBalanceModel? _walkerBalance;
  List<TransactionModel> _walkerTransactions = [];
  bool _isLoading = false;
  String? _error;

  List<TransactionModel> get ownerTransactions =>
      List.unmodifiable(_ownerTransactions);
  WalkerBalanceModel? get walkerBalance => _walkerBalance;
  List<TransactionModel> get walkerTransactions =>
      List.unmodifiable(_walkerTransactions);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Simulates payment: creates transaction with status 'approved' and updates walker_balance
  Future<TransactionModel?> createTransaction({
    required String bookingId,
    required String walkerId,
    required String walkerUserId,
    required String ownerId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final walkerAmount =
          amount * (1 - AppConstants.platformCommission);

      final data = await SupabaseService.client
          .from('transactions')
          .insert({
            'booking_id': bookingId,
            'walker_id': walkerId,
            'owner_id': ownerId,
            'amount': amount,
            'status': 'approved',
            'payment_method': paymentMethod,
            'created_at': now,
            'completed_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      // Update walker balance
      await SupabaseService.client.from('walker_balance').upsert({
        'walker_id': walkerUserId,
        'total_earned': walkerAmount,
        'available_balance': walkerAmount,
        'pending_balance': 0,
        'updated_at': now,
      }, onConflict: 'walker_id');

      // Try to increment (using raw update)
      try {
        final existing = await SupabaseService.client
            .from('walker_balance')
            .select()
            .eq('walker_id', walkerUserId)
            .maybeSingle();
        if (existing != null) {
          final currentTotal =
              (existing['total_earned'] as num?)?.toDouble() ?? 0;
          final currentAvailable =
              (existing['available_balance'] as num?)?.toDouble() ?? 0;
          await SupabaseService.client
              .from('walker_balance')
              .update({
                'total_earned': currentTotal + walkerAmount,
                'available_balance': currentAvailable + walkerAmount,
                'updated_at': now,
              })
              .eq('walker_id', walkerUserId);
        } else {
          await SupabaseService.client.from('walker_balance').insert({
            'walker_id': walkerUserId,
            'total_earned': walkerAmount,
            'available_balance': walkerAmount,
            'pending_balance': 0,
            'updated_at': now,
          });
        }
      } catch (e) {
        debugPrint('[PaymentProvider] wallet update: $e');
      }

      return TransactionModel.fromMap(data);
    } catch (e) {
      debugPrint('[PaymentProvider] createTransaction: $e');
      _error = 'Error al procesar el pago.';
      return null;
    }
  }

  Future<void> loadOwnerTransactions(String ownerId) async {
    _setLoading(true);
    try {
      final data = await SupabaseService.client
          .from('transactions')
          .select()
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);
      _ownerTransactions =
          (data as List).map((e) => TransactionModel.fromMap(e)).toList();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar transacciones.';
      debugPrint('[PaymentProvider] loadOwnerTransactions: $e');
    }
    _setLoading(false);
  }

  Future<void> loadWalkerBalance(String walkerUserId) async {
    _setLoading(true);
    try {
      final balData = await SupabaseService.client
          .from('walker_balance')
          .select()
          .eq('walker_id', walkerUserId)
          .maybeSingle();
      _walkerBalance =
          balData != null ? WalkerBalanceModel.fromMap(balData) : null;

      final txData = await SupabaseService.client
          .from('transactions')
          .select()
          .eq('walker_id', walkerUserId)
          .order('created_at', ascending: false);
      _walkerTransactions =
          (txData as List).map((e) => TransactionModel.fromMap(e)).toList();
      _error = null;
    } catch (e) {
      _error = 'Error al cargar balance.';
      debugPrint('[PaymentProvider] loadWalkerBalance: $e');
    }
    _setLoading(false);
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }
}
