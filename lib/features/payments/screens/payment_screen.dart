import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/payment_provider.dart';
import '../../../core/models/booking_model.dart';
import '../../../features/auth/providers/auth_provider.dart';
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

class _PaymentScreenState extends State<PaymentScreen> with WidgetsBindingObserver {
  bool _processing = false;
  bool _waitingForPayment = false;
  Timer? _pollTimer;

  double get _serviceTotal {
    if (widget.booking.totalAmount != null && widget.booking.totalAmount! > 0) {
      return widget.booking.totalAmount!;
    }
    return widget.booking.servicePrice ?? 0;
  }

  double get _platformCommission =>
      _serviceTotal * AppConstants.platformCommission;

  double get _wompiFee {
    final base = _serviceTotal * AppConstants.wompiPercentage + AppConstants.wompiFixed;
    return base + base * AppConstants.wompiIva;
  }

  double get _grandTotal => _serviceTotal + _platformCommission + _wompiFee;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  // Cuando el usuario vuelve a la app después de pagar en Wompi
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _waitingForPayment) {
      _startPolling();
    }
  }

  Future<void> _pay() async {
    if (_serviceTotal <= 0) {
      _showError('No se encontró el monto del servicio.');
      return;
    }

    setState(() => _processing = true);

    final auth = context.read<AuthProvider>();
    final provider = context.read<PaymentProvider>();

    final url = await provider.createWompiPaymentLink(
      bookingId: widget.booking.id,
      totalAmount: _grandTotal,
      ownerEmail: auth.userModel?.email ?? '',
      ownerName: auth.userModel?.email ?? '',
    );

    setState(() => _processing = false);

    if (url == null) {
      _showError(provider.error ?? 'Error al generar link de pago');
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() => _waitingForPayment = true);
    } else {
      _showError('No se pudo abrir el link de pago');
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    // Verifica el estado cada 3 segundos hasta 2 minutos
    int attempts = 0;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      attempts++;
      if (attempts > 40 || !mounted) {
        timer.cancel();
        setState(() => _waitingForPayment = false);
        return;
      }

      final status = await context
          .read<PaymentProvider>()
          .checkPaymentStatus(widget.booking.id);

      if (status == 'approved') {
        timer.cancel();
        if (!mounted) return;
        setState(() => _waitingForPayment = false);
        Navigator.of(context).pushReplacementNamed('/owner-home');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pago exitoso! El paseador ha sido notificado.'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (status == 'declined' || status == 'failed') {
        timer.cancel();
        if (!mounted) return;
        setState(() => _waitingForPayment = false);
        _showError('El pago fue rechazado. Inténtalo de nuevo.');
      }
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
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
            if (_waitingForPayment)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Verificando tu pago... Vuelve a la app después de completar el pago en Wompi.',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

            // Resumen
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
                    const SizedBox(height: 4),
                    _SummaryRow(
                      label: 'El paseador recibe',
                      value: '\$${numFmt.format(_serviceTotal)} COP',
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
                'La comisión de plataforma y el fee de Wompi se cobran adicional al precio del servicio.',
                style: AppTextStyles.caption,
              ),
            ),
            const SizedBox(height: 32),
            CustomElevatedButton(
              label: _waitingForPayment
                  ? 'Esperando confirmación...'
                  : 'Pagar \$${numFmt.format(_grandTotal.roundToDouble())} COP con Wompi',
              isLoading: _processing,
              onPressed: _waitingForPayment ? null : _pay,
            ),
            if (_waitingForPayment) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _startPolling,
                  child: const Text('Ya pagué, verificar ahora'),
                ),
              ),
            ],
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
