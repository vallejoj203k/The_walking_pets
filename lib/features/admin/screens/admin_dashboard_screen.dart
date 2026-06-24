import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/admin_provider.dart';
import '../widgets/stat_card.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AdminProvider adminProvider;
  const AdminDashboardScreen({super.key, required this.adminProvider});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await widget.adminProvider.getDashboardStats();
    if (mounted) setState(() { _stats = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final walkers = _stats['walkers'] as int? ?? 0;
    final owners = _stats['owners'] as int? ?? 0;
    final totalBookings = _stats['totalBookings'] as int? ?? 0;
    final completed = _stats['completedBookings'] as int? ?? 0;
    final revenue = (_stats['totalRevenue'] as double? ?? 0);
    final fees = (_stats['totalFees'] as double? ?? 0);
    final avgRating = (_stats['avgRating'] as double? ?? 0);
    final openTickets = _stats['openTickets'] as int? ?? 0;
    final monthlyBk =
        (_stats['monthlyBookings'] as Map?)?.cast<String, int>() ?? {};

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Resumen general', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              StatCard(
                title: 'Paseadores',
                value: '$walkers',
                icon: Icons.directions_walk,
                color: AppColors.primary,
              ),
              StatCard(
                title: 'Dueños',
                value: '$owners',
                icon: Icons.person,
                color: AppColors.accent,
              ),
              StatCard(
                title: 'Reservas totales',
                value: '$totalBookings',
                icon: Icons.calendar_month,
                color: Colors.purple,
                subtitle: '$completed completadas',
              ),
              StatCard(
                title: 'Ingresos brutos',
                value: '\$${_fmt(revenue)}',
                icon: Icons.attach_money,
                color: AppColors.success,
                subtitle: 'Comisiones: \$${_fmt(fees)}',
              ),
              StatCard(
                title: 'Rating promedio',
                value: avgRating.toStringAsFixed(1),
                icon: Icons.star,
                color: Colors.amber,
              ),
              StatCard(
                title: 'Tickets abiertos',
                value: '$openTickets',
                icon: Icons.support_agent,
                color: openTickets > 0 ? AppColors.error : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (monthlyBk.isNotEmpty) ...[
            Text('Reservas por mes (últimos 6 meses)',
                style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            _MonthlyBookingsChart(data: monthlyBk),
          ],
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }
}

class _MonthlyBookingsChart extends StatelessWidget {
  final Map<String, int> data;
  const _MonthlyBookingsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.toList();
    final bars = keys.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: (data[e.value] ?? 0).toDouble(),
            color: AppColors.primary,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    final maxY = (data.values.fold<int>(0, (a, b) => a > b ? a : b) + 2)
        .toDouble();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              maxY: maxY < 4 ? 4 : maxY,
              barGroups: bars,
              gridData: const FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: 1),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxY > 10 ? (maxY / 5).ceilToDouble() : 1,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    reservedSize: 28,
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) {
                      final idx = v.toInt();
                      if (idx < 0 || idx >= keys.length) return const SizedBox();
                      final parts = keys[idx].split('-');
                      final month = int.tryParse(parts[1]) ?? 0;
                      const names = [
                        '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                        'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
                      ];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          names[month],
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 22,
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
