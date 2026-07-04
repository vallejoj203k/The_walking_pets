class WithdrawalRequestModel {
  final String id;
  final String walkerId;
  final double amount;
  final String bankName;
  final String accountType;
  final String accountNumber;
  final String walkerName;
  final String walkerEmail;
  final String legalId;
  final String status;
  final String? notes;
  final DateTime createdAt;

  WithdrawalRequestModel({
    required this.id,
    required this.walkerId,
    required this.amount,
    required this.bankName,
    required this.accountType,
    required this.accountNumber,
    required this.walkerName,
    required this.walkerEmail,
    required this.legalId,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  factory WithdrawalRequestModel.fromMap(Map<String, dynamic> map) {
    return WithdrawalRequestModel(
      id: map['id'] as String,
      walkerId: map['walker_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      bankName: map['bank_name'] as String,
      accountType: map['account_type'] as String,
      accountNumber: map['account_number'] as String,
      walkerName: map['walker_name'] as String,
      walkerEmail: map['walker_email'] as String,
      legalId: map['legal_id'] as String,
      status: map['status'] as String,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'processed': return 'Procesado';
      case 'failed': return 'Fallido';
      default: return 'Pendiente';
    }
  }
}
