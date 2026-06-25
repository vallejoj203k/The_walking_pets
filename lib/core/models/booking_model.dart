class BookingModel {
  final String id;
  final String walkerId;
  final String ownerId;
  final String? serviceId;
  final String petId;          // primera mascota (compatibilidad)
  final List<String> petIds;   // todas las mascotas seleccionadas
  final double? totalAmount;   // monto total cobrado al dueño
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
  String? walkerUserId;
  String? ownerUserId;

  BookingModel({
    required this.id,
    required this.walkerId,
    required this.ownerId,
    this.serviceId,
    required this.petId,
    List<String>? petIds,
    this.totalAmount,
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
  }) : petIds = petIds ?? [petId];

  factory BookingModel.fromMap(Map<String, dynamic> map) {
    final petId = map['pet_id'] as String;
    final rawIds = map['pet_ids'];
    List<String> petIds;
    if (rawIds is List && rawIds.isNotEmpty) {
      petIds = List<String>.from(rawIds);
    } else {
      petIds = [petId];
    }
    return BookingModel(
      id: map['id'] as String,
      walkerId: map['walker_id'] as String,
      ownerId: map['owner_id'] as String,
      serviceId: map['service_id'] as String?,
      petId: petId,
      petIds: petIds,
      totalAmount: (map['total_amount'] as num?)?.toDouble(),
      status: map['status'] as String,
      scheduledDate: DateTime.parse(map['scheduled_date'] as String).toLocal(),
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  int get additionalPets => petIds.length > 1 ? petIds.length - 1 : 0;

  String get statusLabel {
    switch (status) {
      case 'pending': return 'Pendiente';
      case 'accepted': return 'Aceptado';
      case 'in_progress': return 'En progreso';
      case 'completed': return 'Completado';
      case 'cancelled': return 'Cancelado';
      default: return status;
    }
  }

  bool get canCancel => status == 'pending' || status == 'accepted';
  bool get canComplete => status == 'in_progress';
  bool get isActive =>
      status == 'pending' || status == 'accepted' || status == 'in_progress';
}
