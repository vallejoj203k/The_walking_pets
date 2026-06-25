import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  String _selectedMethod = 'wompi';
  bool _processing = false;

  final _methods = [
    {'id': 'wompi', 'label': 'Wompi (tarjeta / PSE)', 'icon': Icons.credit_card},
    {'id': 'bank_transfer', 'label': 'Transferencia Bancaria', 'icon': Icons.account_balance},
    {'id': 'cash', 'label': 'Efectivo', 'icon': Icons.money},
  ];

  // Service total (base + additional pets at 40%)
  double get _serviceTotal {
    if (widget.booking.totalAmount != null && widget.booking.totalAmount! > 0) {
      return widget.booking.totalAmount!;
    }
    return widget.booking.servicePrice ?? 0;
  }

  double get _platformCommission =>
      _serviceTotal * AppConstants.platformCommission;

  // Wompi fee: 2.65% + $700 + 19% IVA on that fee
  double get _wompiFee {
    final base = _serviceTotal * AppConstants.wompiPercentage + AppConstants.wompiFixed;
    return base + base * AppConstants.wompiIva;
  }

  double get _grandTotal => _serviceTotal + _platformCommission + _wompiFee;

  // Walker receives the full service total (platform and Wompi are charged on top)
  double get _walkerReceives => _serviceTotal;

  Future<void> _pay() async {
    if (_serviceTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el monto del servicio.')),
      );
      return;
    }
    setState(() => _processing = true);

    final profile = context.read<ProfileProvider>();
    final ownerId = profile.owner?.id ?? '';

    final tx = await context.read<PaymentProvider>().createTransaction(
          bookingId: widget.booking.id,
          walkerId: widget.booking.walkerId,
          walkerUserId: widget.walkerUserId,
          ownerId: ownerId,
          amount: _grandTotal,
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
    final numFmt = NumberFormat('#,###', 'es_CO');
    final additionalPets = widget.booking.additionalPets;
    final basePrice = widget.booking.servicePrice ?? 0;

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
                    Text('Resumen del servicio', style: AppTextStyles.heading3),
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
                      label: 'Mascota(s)',
                      value: widget.booking.petIds.length > 1
                          ? '${widget.booking.petIds.length} mascotas'
                          : (widget.booking.petName ?? '-'),
                    ),
                    if (basePrice > 0) ...[
                      const SizedBox(height: 8),
                      _SummaryRow(
                        label: 'Precio base',
                        value: '\$${numFmt.format(basePrice)} COP',
                      ),
                      if (additionalPets > 0)
                        _SummaryRow(
                          label: '$additionalPets mascota${additionalPets > 1 ? 's' : ''} adicional${additionalPets > 1 ? 'es' : ''} (40%)',
                          value: '+\$${numFmt.format(additionalPets * basePrice * AppConstants.additionalPetRate)} COP',
                          secondary: true,
                        ),
                    ],
                    const Divider(height: 20),
                    _SummaryRow(
                      label: 'Subtotal servicio',
                      value: '\$${numFmt.format(_serviceTotal)} COP',
                    ),
                    _SummaryRow(
                      label: 'Comisión plataforma (10%)',
                      value: '+\$${numFmt.format(_platformCommission)} COP',
                      secondary: true,
                    ),
                    _SummaryRow(
                      label: 'Fee Wompi (2.65% + \$700 + IVA)',
                      value: '+\$${numFmt.format(_wompiFee.roundToDouble())} COP',
                      secondary: true,
                    ),
                    const Divider(height: 16),
                    _SummaryRow(
                      label: 'Total a pagar',
                      value: '\$${numFmt.format(_grandTotal.roundToDouble())} COP',
                      bold: true,
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'El paseador recibe',
                      value: '\$${numFmt.format(_walkerReceives)} COP',
                      secondary: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'La comisión de plataforma y el fee de Wompi se cobran sobre el precio del servicio. El paseador recibe el precio del servicio completo.',
                style: AppTextStyles.caption,
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
                        Icon(m['icon'] as IconData, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(m['label'] as String, style: AppTextStyles.body),
                      ],
                    ),
                    value: m['id'] as String,
                    groupValue: _selectedMethod,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _selectedMethod = v!),
                  ),
                )),
            const SizedBox(height: 32),
            CustomElevatedButton(
              label: 'Pagar \$${numFmt.format(_grandTotal.roundToDouble())} COP',
              isLoading: _processing,
              onPressed: _pay,
            ),
            const SizedBox(height: 32),
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
          Expanded(
            child: Text(
              label,
              style: secondary ? AppTextStyles.caption : AppTextStyles.bodySecondary,
            ),
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
