import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/payment_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state.dart';
import 'withdrawal_screen.dart';
import '../../../core/models/withdrawal_request_model.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().userModel?.id;
    if (userId == null) return;
    await context.read<PaymentProvider>().loadWalkerBalance(userId);
  }

  @override
  Widget build(BuildContext context) {
    final payment = context.watch<PaymentProvider>();
    final balance = payment.walkerBalance;
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Mi Billetera',
        showBack: false,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: payment.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: AppColors.primary,
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        children: [
                          Text('Balance disponible',
                              style: AppTextStyles.body
                                  .copyWith(color: Colors.white70)),
                          const SizedBox(height: 8),
                          Text(
                            '\$${(balance?.availableBalance ?? 0).toStringAsFixed(0)} COP',
                            style: AppTextStyles.heading2.copyWith(
                                color: Colors.white, fontSize: 36),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              _BalanceStat(
                                label: 'Total ganado',
                                value:
                                    '\$${(balance?.totalEarned ?? 0).toStringAsFixed(0)}',
                              ),
                              _BalanceStat(
                                label: 'Pendiente',
                                value:
                                    '\$${(balance?.pendingBalance ?? 0).toStringAsFixed(0)}',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.account_balance),
                              label: const Text('Retirar fondos'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: (balance?.availableBalance ?? 0) > 0
                                  ? () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => WithdrawalScreen(
                                            availableBalance: balance!.availableBalance,
                                          ),
                                        ),
                                      ).then((_) => _load())
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pagos recibidos',
                              style: AppTextStyles.heading3),
                          const SizedBox(height: 12),
                          if (payment.walkerTransactions.isEmpty)
                            const EmptyState(
                              message: 'Aún no has recibido pagos.',
                              icon: Icons.account_balance_wallet_outlined,
                            )
                          else
                            ...payment.walkerTransactions.map((tx) => Card(
                                  margin:
                                      const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          AppColors.successLight,
                                      child: const Icon(Icons.arrow_downward,
                                          color: AppColors.success),
                                    ),
                                    title: Text(
                                      '\$${tx.amount.toStringAsFixed(0)} COP',
                                      style: AppTextStyles.body,
                                    ),
                                    subtitle: Text(
                                      '${tx.paymentMethodLabel}\n${fmt.format(tx.createdAt)}',
                                      style: AppTextStyles.caption,
                                    ),
                                    trailing: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.successLight,
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Text(tx.statusLabel,
                                          style: AppTextStyles.caption
                                              .copyWith(
                                                  color:
                                                      AppColors.success)),
                                    ),
                                  ),
                                )),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Historial de retiros',
                              style: AppTextStyles.heading3),
                          const SizedBox(height: 12),
                          if (payment.withdrawalRequests.isEmpty)
                            const EmptyState(
                              message: 'Aún no has solicitado retiros.',
                              icon: Icons.account_balance_outlined,
                            )
                          else
                            ...payment.withdrawalRequests
                                .map((wr) => _WithdrawalTile(wr: wr, fmt: fmt)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _WithdrawalTile extends StatelessWidget {
  final WithdrawalRequestModel wr;
  final DateFormat fmt;

  const _WithdrawalTile({required this.wr, required this.fmt});

  Color get _statusColor {
    switch (wr.status) {
      case 'processed': return AppColors.success;
      case 'failed': return AppColors.error;
      default: return Colors.orange;
    }
  }

  Color get _statusBg {
    switch (wr.status) {
      case 'processed': return AppColors.successLight;
      case 'failed': return AppColors.error.withOpacity(0.1);
      default: return Colors.orange.withOpacity(0.1);
    }
  }

  IconData get _statusIcon {
    switch (wr.status) {
      case 'processed': return Icons.check_circle_outline;
      case 'failed': return Icons.error_outline;
      default: return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusBg,
          child: Icon(_statusIcon, color: _statusColor),
        ),
        title: Text(
          '\$${wr.amount.toStringAsFixed(0)} COP',
          style: AppTextStyles.body,
        ),
        subtitle: Text(
          '${wr.bankName} · ${wr.accountType}\n${fmt.format(wr.createdAt)}',
          style: AppTextStyles.caption,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            wr.statusLabel,
            style: AppTextStyles.caption.copyWith(color: _statusColor),
          ),
        ),
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final String value;

  const _BalanceStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.heading3
                .copyWith(color: Colors.white)),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: Colors.white70)),
      ],
    );
  }
}
