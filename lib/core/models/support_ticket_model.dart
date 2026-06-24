class SupportTicketModel {
  final String id;
  final String userId;
  final String category;
  final String subject;
  final String description;
  String status;
  final String priority;
  String? adminResponse;
  final DateTime createdAt;
  DateTime? resolvedAt;

  // Joined
  String? userName;
  String? userEmail;

  SupportTicketModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.adminResponse,
    required this.createdAt,
    this.resolvedAt,
    this.userName,
    this.userEmail,
  });

  factory SupportTicketModel.fromMap(Map<String, dynamic> m) {
    return SupportTicketModel(
      id: m['id'] as String,
      userId: m['user_id'] as String,
      category: m['category'] as String? ?? 'other',
      subject: m['subject'] as String,
      description: m['description'] as String,
      status: m['status'] as String? ?? 'open',
      priority: m['priority'] as String? ?? 'medium',
      adminResponse: m['admin_response'] as String?,
      createdAt: DateTime.parse(m['created_at'] as String),
      resolvedAt: m['resolved_at'] != null
          ? DateTime.parse(m['resolved_at'] as String)
          : null,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'open': return 'Abierto';
      case 'in_progress': return 'En progreso';
      case 'resolved': return 'Resuelto';
      case 'closed': return 'Cerrado';
      default: return status;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'high': return 'Alta';
      case 'medium': return 'Media';
      case 'low': return 'Baja';
      default: return priority;
    }
  }

  String get categoryLabel {
    switch (category) {
      case 'payment': return 'Pago';
      case 'booking': return 'Reserva';
      case 'profile': return 'Perfil';
      default: return 'Otro';
    }
  }
}
