class TransactionModel {
  final String id;
  final String bookingId;
  final String walkerId;
  final String ownerId;
  final double amount;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime? completedAt;

  TransactionModel({
    required this.id,
    required this.bookingId,
    required this.walkerId,
    required this.ownerId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.completedAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      bookingId: map['booking_id'] as String,
      walkerId: map['walker_id'] as String,
      ownerId: map['owner_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      status: map['status'] as String,
      paymentMethod: map['payment_method'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String).toLocal()
          : null,
    );
  }

  String get paymentMethodLabel {
    switch (paymentMethod) {
      case 'mercadopago':
        return 'MercadoPago';
      case 'bank_transfer':
        return 'Transferencia Bancaria';
      case 'cash':
        return 'Efectivo';
      default:
        return paymentMethod;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobado';
      case 'failed':
        return 'Fallido';
      case 'refunded':
        return 'Reembolsado';
      default:
        return status;
    }
  }
}

class WalkerBalanceModel {
  final String walkerId;
  final double totalEarned;
  final double availableBalance;
  final double pendingBalance;

  WalkerBalanceModel({
    required this.walkerId,
    required this.totalEarned,
    required this.availableBalance,
    required this.pendingBalance,
  });

  factory WalkerBalanceModel.fromMap(Map<String, dynamic> map) {
    return WalkerBalanceModel(
      walkerId: map['walker_id'] as String,
      totalEarned: (map['total_earned'] as num?)?.toDouble() ?? 0,
      availableBalance: (map['available_balance'] as num?)?.toDouble() ?? 0,
      pendingBalance: (map['pending_balance'] as num?)?.toDouble() ?? 0,
    );
  }
}
