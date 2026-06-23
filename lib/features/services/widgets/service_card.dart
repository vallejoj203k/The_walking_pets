import 'package:flutter/material.dart';
import '../../../core/models/service_model.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onToggleActive;
  final bool showActions;

  const ServiceCard({
    super.key,
    required this.service,
    this.onEdit,
    this.onDelete,
    this.onToggleActive,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(service.typeEmoji,
                        style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.typeLabel,
                          style: AppTextStyles.heading3),
                      Text(
                        service.priceSummary,
                        style: AppTextStyles.body
                            .copyWith(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                if (showActions && onToggleActive != null)
                  Switch(
                    value: service.isActive,
                    onChanged: onToggleActive,
                    activeColor: AppColors.success,
                  ),
              ],
            ),
            if (service.description != null &&
                service.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(service.description!,
                  style: AppTextStyles.bodySecondary),
            ],
            if (!service.isActive) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Inactivo',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
            ],
            if (showActions && (onEdit != null || onDelete != null)) ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Editar'),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: AppColors.error),
                      label: const Text('Eliminar',
                          style: TextStyle(color: AppColors.error)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
