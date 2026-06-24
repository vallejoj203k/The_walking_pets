import 'package:flutter/material.dart';
import '../../../core/models/transaction_model.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../widgets/custom_elevated_button.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final TransactionModel transaction;

  const PaymentSuccessScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle,
                  color: AppColors.success, size: 100),
              const SizedBox(height: 24),
              Text('¡Pago exitoso!',
                  style: AppTextStyles.heading2, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Tu pago ha sido procesado correctamente.',
                style: AppTextStyles.bodySecondary,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Monto pagado',
                        value:
                            '\$${transaction.amount.toStringAsFixed(0)} COP',
                        highlight: true,
                      ),
                      const Divider(height: 20),
                      _DetailRow(
                        label: 'Método de pago',
                        value: transaction.paymentMethodLabel,
                      ),
                      _DetailRow(
                        label: 'Estado',
                        value: transaction.statusLabel,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              CustomElevatedButton(
                label: 'Volver a mis reservas',
                onPressed: () => Navigator.of(context)
                    .popUntil((r) => r.isFirst || r.settings.name == '/owner-home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _DetailRow(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySecondary),
          Text(
            value,
            style: highlight
                ? AppTextStyles.heading3.copyWith(color: AppColors.success)
                : AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
