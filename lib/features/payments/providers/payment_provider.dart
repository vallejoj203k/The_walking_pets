import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/models/transaction_model.dart';

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

  /// Llama a la Edge Function de Supabase para crear un link de pago en Wompi.
  /// Retorna la URL de pago o null si hubo error.
  Future<String?> createWompiPaymentLink({
    required String bookingId,
    required double totalAmount,
    required String ownerEmail,
    required String ownerName,
  }) async {
    _error = null;
    try {
      final amountInCents = (totalAmount * 100).round();
      final res = await SupabaseService.client.functions.invoke(
        'create-wompi-payment',
        body: {
          'bookingId': bookingId,
          'amountInCents': amountInCents,
          'description': 'Servicio - The Walking Pets',
          'ownerEmail': ownerEmail,
          'ownerName': ownerName,
        },
      );

      debugPrint('[PaymentProvider] Edge Function status: ${res.status}');
      debugPrint('[PaymentProvider] Edge Function data: ${res.data}');

      if (res.status != 200) {
        final detail = res.data?['detail']?.toString() ?? res.data?.toString() ?? '';
        _error = 'Error al generar el link de pago: $detail';
        notifyListeners();
        return null;
      }

      final url = res.data['paymentUrl'] as String?;
      if (url == null) {
        _error = 'No se recibió URL de pago. Respuesta: ${res.data}';
        notifyListeners();
        return null;
      }
      return url;
    } catch (e) {
      _error = 'Error al conectar con el servidor de pagos';
      debugPrint('[PaymentProvider] createWompiPaymentLink: $e');
      notifyListeners();
      return null;
    }
  }

  /// Verifica el estado del pago consultando Wompi directamente via Edge Function.
  Future<String?> checkPaymentStatus(String bookingId) async {
    try {
      final res = await SupabaseService.client.functions.invoke(
        'check-wompi-payment',
        body: {'bookingId': bookingId},
      );
      debugPrint('[PaymentProvider] checkPaymentStatus: ${res.data}');
      return res.data?['status'] as String?;
    } catch (e) {
      debugPrint('[PaymentProvider] checkPaymentStatus: $e');
      return null;
    }
  }

  Future<bool> requestWithdrawal({
    required String walkerUserId,
    required double amount,
    required String bankName,
    required String accountType,
    required String accountNumber,
    required String walkerName,
    required String walkerEmail,
    required String legalId,
    String legalIdType = 'CC',
  }) async {
    _error = null;
    try {
      final now = DateTime.now().toIso8601String();

      final inserted = await SupabaseService.client
          .from('withdrawal_requests')
          .insert({
            'walker_id': walkerUserId,
            'amount': amount,
            'bank_name': bankName,
            'account_type': accountType,
            'account_number': accountNumber,
            'walker_name': walkerName,
            'walker_email': walkerEmail,
            'legal_id': legalId,
            'legal_id_type': legalIdType,
            'status': 'pending',
            'created_at': now,
            'updated_at': now,
          })
          .select()
          .single();

      // Descontar del balance disponible
      final bal = await SupabaseService.client
          .from('walker_balance')
          .select()
          .eq('walker_id', walkerUserId)
          .maybeSingle();

      if (bal != null) {
        await SupabaseService.client.from('walker_balance').update({
          'available_balance': (bal['available_balance'] as num) - amount,
          'pending_balance': (bal['pending_balance'] as num) + amount,
          'updated_at': now,
        }).eq('walker_id', walkerUserId);
      }

      // Llamar Edge Function para procesar el retiro via Wompi
      final res = await SupabaseService.client.functions.invoke(
        'process-withdrawal',
        body: {'withdrawalRequestId': inserted['id']},
      );
      debugPrint('[PaymentProvider] process-withdrawal: ${res.status} ${res.data}');

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al enviar solicitud de retiro.';
      debugPrint('[PaymentProvider] requestWithdrawal: $e');
      notifyListeners();
      return false;
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
