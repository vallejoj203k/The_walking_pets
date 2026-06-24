import 'package:flutter/material.dart';
import '../providers/admin_provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class TransactionsAdminScreen extends StatefulWidget {
  final AdminProvider adminProvider;
  const TransactionsAdminScreen({super.key, required this.adminProvider});

  @override
  State<TransactionsAdminScreen> createState() =>
      _TransactionsAdminScreenState();
}

class _TransactionsAdminScreenState extends State<TransactionsAdminScreen> {
  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String? _statusFilter;

  double get _totalAmount => _filtered.fold(
      0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));
  double get _totalFees => _totalAmount * 0.10;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final t = await widget.adminProvider.getAllTransactions();
    if (mounted) {
      setState(() {
        _all = t;
        _filtered = t;
        _loading = false;
      });
    }
  }

  void _filter() {
    setState(() {
      _filtered = _statusFilter == null
          ? _all
          : _all.where((t) => t['status'] == _statusFilter).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Summary row
        if (!_loading)
          Container(
            color: AppColors.primaryLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryItem(
                    label: 'Total procesado',
                    value: '\$${_fmt(_totalAmount)}'),
                _SummaryItem(
                    label: 'Comisiones',
                    value: '\$${_fmt(_totalFees)}'),
                _SummaryItem(
                    label: 'Transacciones',
                    value: '${_filtered.length}'),
              ],
            ),
          ),
        // Filter row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const Text('Estado: ', style: TextStyle(fontWeight: FontWeight.w500)),
              DropdownButton<String?>(
                value: _statusFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'approved', child: Text('Aprobado')),
                  DropdownMenuItem(value: 'pending', child: Text('Pendiente')),
                  DropdownMenuItem(value: 'failed', child: Text('Fallido')),
                  DropdownMenuItem(value: 'refunded', child: Text('Reembolsado')),
                ],
                onChanged: (v) {
                  _statusFilter = v;
                  _filter();
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('Sin transacciones.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final t = _filtered[i];
                          final amount =
                              (t['amount'] as num?)?.toDouble() ?? 0;
                          final status = t['status'] as String? ?? '';
                          final method =
                              t['payment_method'] as String? ?? '-';
                          final date =
                              t['created_at'] as String? ?? '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: _StatusBadge(status: status),
                              title: Text(
                                '\$${amount.toStringAsFixed(0)} COP',
                                style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text(
                                '$method · ${_fmtDate(date)}',
                                style: AppTextStyles.caption,
                              ),
                              trailing: Text(
                                'Fee: \$${(amount * 0.10).toStringAsFixed(0)}',
                                style: AppTextStyles.caption
                                    .copyWith(color: AppColors.success),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.heading3
                .copyWith(color: AppColors.primaryDark)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status) {
      case 'approved':
        color = AppColors.success; icon = Icons.check_circle; break;
      case 'pending':
        color = AppColors.accent; icon = Icons.hourglass_empty; break;
      case 'failed':
        color = AppColors.error; icon = Icons.cancel; break;
      case 'refunded':
        color = Colors.purple; icon = Icons.replay; break;
      default:
        color = AppColors.textSecondary; icon = Icons.help;
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: color.withOpacity(0.15),
      child: Icon(icon, size: 18, color: color),
    );
  }
}
