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

  /// Verifica el estado de la transacción de un booking en Supabase.
  Future<String?> checkPaymentStatus(String bookingId) async {
    try {
      final data = await SupabaseService.client
          .from('transactions')
          .select('status')
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return data?['status'] as String?;
    } catch (e) {
      debugPrint('[PaymentProvider] checkPaymentStatus: $e');
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
