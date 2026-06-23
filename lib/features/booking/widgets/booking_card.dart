import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/booking_model.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import 'booking_status_badge.dart';

class BookingCard extends StatelessWidget {
  final BookingModel booking;
  final bool isWalkerView;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final VoidCallback? onTap;

  const BookingCard({
    super.key,
    required this.booking,
    this.isWalkerView = false,
    this.onAccept,
    this.onReject,
    this.onCancel,
    this.onComplete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');
    final person = isWalkerView ? booking.ownerName : booking.walkerName;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWalkerView
                              ? 'Solicitud de ${person ?? 'Dueño'}'
                              : 'Paseador: ${person ?? 'Paseador'}',
                          style: AppTextStyles.heading3,
                        ),
                        if (booking.petName != null)
                          Text('Mascota: ${booking.petName}',
                              style: AppTextStyles.bodySecondary),
                      ],
                    ),
                  ),
                  BookingStatusBadge(status: booking.status),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(fmt.format(booking.scheduledDate),
                      style: AppTextStyles.bodySecondary),
                ],
              ),
              if (booking.serviceType != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.pets,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      '${_capitalize(booking.serviceType!)}${booking.servicePrice != null ? ' · \$${booking.servicePrice!.toStringAsFixed(0)} COP/h' : ''}',
                      style: AppTextStyles.bodySecondary,
                    ),
                  ],
                ),
              ],
              if (booking.notes != null && booking.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Nota: ${booking.notes}',
                    style: AppTextStyles.caption),
              ],
              if (_hasActions()) ...[
                const SizedBox(height: 12),
                _buildActions(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _hasActions() {
    return (isWalkerView &&
            booking.status == 'pending' &&
            (onAccept != null || onReject != null)) ||
        (booking.canCancel && onCancel != null) ||
        (booking.canComplete && onComplete != null);
  }

  Widget _buildActions() {
    return Wrap(
      spacing: 8,
      children: [
        if (isWalkerView && booking.status == 'pending') ...[
          if (onAccept != null)
            ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Aceptar'),
            ),
          if (onReject != null)
            OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Rechazar'),
            ),
        ],
        if (booking.canCancel && onCancel != null && !isWalkerView)
          OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Cancelar'),
          ),
        if (booking.canComplete && onComplete != null)
          ElevatedButton(
            onPressed: onComplete,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Completar'),
          ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
