import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

const _banks = [
  'Bancolombia', 'Banco de Bogotá', 'Davivienda', 'BBVA', 'Nequi',
  'Daviplata', 'Banco Popular', 'AV Villas', 'Banco de Occidente',
  'Banco Caja Social', 'Scotiabank Colpatria', 'Otro',
];

const _accountTypes = ['Ahorros', 'Corriente'];

class WithdrawalScreen extends StatefulWidget {
  final double availableBalance;

  const WithdrawalScreen({super.key, required this.availableBalance});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _accountCtrl = TextEditingController();
  String? _selectedBank;
  String _accountType = 'Ahorros';
  bool _loading = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _accountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountCtrl.text.replaceAll(',', ''));
    if (amount > widget.availableBalance) {
      _showError('El monto supera tu balance disponible.');
      return;
    }

    setState(() => _loading = true);

    final userId = context.read<AuthProvider>().userModel!.id;
    final success = await context.read<PaymentProvider>().requestWithdrawal(
      walkerUserId: userId,
      amount: amount,
      bankName: _selectedBank!,
      accountType: _accountType,
      accountNumber: _accountCtrl.text.trim(),
    );

    setState(() => _loading = false);
    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitud de retiro enviada. Se procesará en 1-3 días hábiles.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 5),
        ),
      );
    } else {
      _showError(context.read<PaymentProvider>().error ?? 'Error al enviar solicitud.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  final fmt = NumberFormat('#,###', 'es_CO');

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Solicitar retiro'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance disponible
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text('Balance disponible',
                        style: AppTextStyles.body.copyWith(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      '\$${fmt.format(widget.availableBalance)} COP',
                      style: AppTextStyles.heading2.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text('Datos bancarios', style: AppTextStyles.heading3),
              const SizedBox(height: 16),

              // Banco
              DropdownButtonFormField<String>(
                value: _selectedBank,
                decoration: const InputDecoration(
                  labelText: 'Banco',
                  border: OutlineInputBorder(),
                ),
                items: _banks
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedBank = v),
                validator: (v) => v == null ? 'Selecciona un banco' : null,
              ),
              const SizedBox(height: 16),

              // Tipo de cuenta
              DropdownButtonFormField<String>(
                value: _accountType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de cuenta',
                  border: OutlineInputBorder(),
                ),
                items: _accountTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _accountType = v!),
              ),
              const SizedBox(height: 16),

              // Número de cuenta
              TextFormField(
                controller: _accountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de cuenta',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresa el número de cuenta';
                  if (v.trim().length < 6) return 'Número de cuenta inválido';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              Text('Monto a retirar', style: AppTextStyles.heading3),
              const SizedBox(height: 16),

              // Monto
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto a retirar (COP)',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa el monto';
                  final amount = double.tryParse(v.replaceAll(',', ''));
                  if (amount == null || amount <= 0) return 'Monto inválido';
                  if (amount < 10000) return 'El monto mínimo es \$10,000 COP';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Desglose de fees
              Builder(builder: (context) {
                final raw = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0;
                if (raw <= 0) return const SizedBox.shrink();
                final fee = (1849 + raw * 0.004) * 1.19;
                final received = raw - fee;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      _FeeRow(label: 'Monto solicitado', value: '\$${fmt.format(raw)} COP'),
                      _FeeRow(label: 'Fee Wompi (\$1.849 + 0.4% + IVA)', value: '-\$${fmt.format(fee.roundToDouble())} COP', secondary: true),
                      const Divider(height: 16),
                      _FeeRow(label: 'Recibirás en tu cuenta', value: '\$${fmt.format(received.roundToDouble())} COP', bold: true),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                'El retiro se procesará en 1-3 días hábiles.',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 32),

              CustomElevatedButton(
                label: 'Solicitar retiro',
                isLoading: _loading,
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool secondary;

  const _FeeRow({required this.label, required this.value, this.bold = false, this.secondary = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: secondary ? AppTextStyles.caption : AppTextStyles.bodySecondary)),
          Text(value, style: bold ? AppTextStyles.heading3 : secondary ? AppTextStyles.caption : AppTextStyles.body),
        ],
      ),
    );
  }
}
