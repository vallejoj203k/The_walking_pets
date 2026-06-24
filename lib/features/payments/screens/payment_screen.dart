import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import 'payment_success_screen.dart';
import '../../../core/models/booking_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants/app_constants.dart';

class PaymentScreen extends StatefulWidget {
  final BookingModel booking;
  final String walkerUserId;

  const PaymentScreen({
    super.key,
    required this.booking,
    required this.walkerUserId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'mercadopago';
  bool _processing = false;

  final _methods = [
    {'id': 'mercadopago', 'label': 'MercadoPago', 'icon': Icons.payment},
    {
      'id': 'bank_transfer',
      'label': 'Transferencia Bancaria',
      'icon': Icons.account_balance
    },
    {'id': 'cash', 'label': 'Efectivo', 'icon': Icons.money},
  ];

  double get _amount => widget.booking.servicePrice ?? 0;
  double get _walkerAmount =>
      _amount * (1 - AppConstants.platformCommission);
  double get _commission => _amount * AppConstants.platformCommission;

  Future<void> _pay() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'No se encontró el monto del servicio.')),
      );
      return;
    }
    setState(() => _processing = true);

    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final ownerId = profile.owner?.id ?? '';

    final tx = await context.read<PaymentProvider>().createTransaction(
          bookingId: widget.booking.id,
          walkerId: widget.booking.walkerId,
          walkerUserId: widget.walkerUserId,
          ownerId: ownerId,
          amount: _amount,
          paymentMethod: _selectedMethod,
        );

    setState(() => _processing = false);
    if (!mounted) return;

    if (tx != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(transaction: tx),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al procesar el pago. Inténtalo de nuevo.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Pagar servicio'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen del servicio',
                        style: AppTextStyles.heading3),
                    const Divider(height: 20),
                    _SummaryRow(
                      label: 'Paseador',
                      value: widget.booking.walkerName ?? '-',
                    ),
                    _SummaryRow(
                      label: 'Servicio',
                      value: _capitalize(widget.booking.serviceType ?? '-'),
                    ),
                    _SummaryRow(
                      label: 'Mascota',
                      value: widget.booking.petName ?? '-',
                    ),
                    const Divider(height: 20),
                    _SummaryRow(
                      label: 'Total',
                      value:
                          '\$${_amount.toStringAsFixed(0)} COP',
                      bold: true,
                    ),
                    _SummaryRow(
                      label:
                          'Comisión plataforma (${(AppConstants.platformCommission * 100).toStringAsFixed(0)}%)',
                      value: '\$${_commission.toStringAsFixed(0)} COP',
                      secondary: true,
                    ),
                    _SummaryRow(
                      label: 'Paseador recibe',
                      value:
                          '\$${_walkerAmount.toStringAsFixed(0)} COP',
                      secondary: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Método de pago', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            ..._methods.map((m) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: _selectedMethod == m['id']
                          ? AppColors.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(m['icon'] as IconData,
                            color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(m['label'] as String,
                            style: AppTextStyles.body),
                      ],
                    ),
                    value: m['id'] as String,
                    groupValue: _selectedMethod,
                    activeColor: AppColors.primary,
                    onChanged: (v) =>
                        setState(() => _selectedMethod = v!),
                  ),
                )),
            const SizedBox(height: 32),
            CustomElevatedButton(
              label: 'Pagar \$${_amount.toStringAsFixed(0)} COP',
              isLoading: _processing,
              onPressed: _pay,
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool secondary;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: secondary
                ? AppTextStyles.caption
                : AppTextStyles.bodySecondary,
          ),
          Text(
            value,
            style: bold
                ? AppTextStyles.heading3
                : secondary
                    ? AppTextStyles.caption
                    : AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
