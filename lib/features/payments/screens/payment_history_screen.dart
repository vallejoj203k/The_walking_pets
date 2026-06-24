import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/payment_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final profile = context.read<ProfileProvider>();
    final ownerId = profile.owner?.id;
    if (ownerId == null) return;
    await context.read<PaymentProvider>().loadOwnerTransactions(ownerId);
  }

  @override
  Widget build(BuildContext context) {
    final payment = context.watch<PaymentProvider>();
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Historial de pagos',
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: payment.isLoading
          ? const Center(child: CircularProgressIndicator())
          : payment.ownerTransactions.isEmpty
              ? const EmptyState(
                  message: 'No tienes pagos registrados aún.',
                  icon: Icons.receipt_long_outlined,
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: payment.ownerTransactions.length,
                    itemBuilder: (_, i) {
                      final tx = payment.ownerTransactions[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '\$${tx.amount.toStringAsFixed(0)} COP',
                                    style: AppTextStyles.heading3,
                                  ),
                                  _StatusChip(status: tx.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(tx.paymentMethodLabel,
                                  style: AppTextStyles.bodySecondary),
                              Text(
                                fmt.format(tx.createdAt),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (status) {
      case 'approved':
        color = AppColors.success;
        label = 'Aprobado';
        break;
      case 'pending':
        color = AppColors.accent;
        label = 'Pendiente';
        break;
      case 'failed':
        color = AppColors.error;
        label = 'Fallido';
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}
