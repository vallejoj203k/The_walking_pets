class BookingModel {
  final String id;
  final String walkerId;
  final String ownerId;
  final String? serviceId;
  final String petId;
  String status;
  final DateTime scheduledDate;
  String? notes;
  final DateTime createdAt;
  DateTime updatedAt;

  // Joined data (optional)
  String? walkerName;
  String? ownerName;
  String? serviceType;
  double? servicePrice;
  String? petName;
  String? walkerUserId; // auth user_id of the walker
  String? ownerUserId; // auth user_id of the owner

  BookingModel({
    required this.id,
    required this.walkerId,
    required this.ownerId,
    this.serviceId,
    required this.petId,
    required this.status,
    required this.scheduledDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.walkerName,
    this.ownerName,
    this.serviceType,
    this.servicePrice,
    this.petName,
    this.walkerUserId,
    this.ownerUserId,
  });

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    return BookingModel(
      id: map['id'] as String,
      walkerId: map['walker_id'] as String,
      ownerId: map['owner_id'] as String,
      serviceId: map['service_id'] as String?,
      petId: map['pet_id'] as String,
      status: map['status'] as String,
      scheduledDate: DateTime.parse(map['scheduled_date'] as String).toLocal(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'walker_id': walkerId,
      'owner_id': ownerId,
      'service_id': serviceId,
      'pet_id': petId,
      'status': status,
      'scheduled_date': scheduledDate.toUtc().toIso8601String(),
      'notes': notes,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'accepted':
        return 'Aceptado';
      case 'in_progress':
        return 'En progreso';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  bool get canCancel =>
      status == 'pending' || status == 'accepted';
  bool get canComplete => status == 'in_progress';
  bool get isActive =>
      status == 'pending' || status == 'accepted' || status == 'in_progress';
}
