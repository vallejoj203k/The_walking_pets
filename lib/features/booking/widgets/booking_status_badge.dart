import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

class BookingStatusBadge extends StatelessWidget {
  final String status;

  const BookingStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final info = _getInfo(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: info.$2.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: info.$2.withOpacity(0.4)),
      ),
      child: Text(
        info.$1,
        style: TextStyle(
          color: info.$2,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (String, Color) _getInfo(String status) {
    switch (status) {
      case 'pending':
        return ('Pendiente', AppColors.accent);
      case 'accepted':
        return ('Aceptado', AppColors.primary);
      case 'in_progress':
        return ('En progreso', AppColors.success);
      case 'completed':
        return ('Completado', const Color(0xFF4CAF50));
      case 'cancelled':
        return ('Cancelado', AppColors.error);
      default:
        return (status, AppColors.textSecondary);
    }
  }
}
