import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/admin_provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class AnalyticsScreen extends StatefulWidget {
  final AdminProvider adminProvider;
  const AnalyticsScreen({super.key, required this.adminProvider});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await widget.adminProvider.getAnalyticsData();
    if (mounted) setState(() { _data = d; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final svcDist = (_data['serviceDistribution'] as Map?)?.cast<String, int>() ?? {};
    final bkStatus = (_data['bookingStatus'] as Map?)?.cast<String, int>() ?? {};
    final monthlyRev =
        (_data['monthlyRevenue'] as Map?)?.cast<String, double>() ?? {};
    final monthlyUsers =
        (_data['monthlyUsers'] as Map?)?.cast<String, int>() ?? {};
    final avgRating = (_data['avgRating'] as double? ?? 0);
    final totalReviews = _data['totalReviews'] as int? ?? 0;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Distribución de servicios'),
          if (svcDist.isNotEmpty) _ServicePieChart(data: svcDist),
          const SizedBox(height: 20),
          _section('Estado de reservas'),
          if (bkStatus.isNotEmpty) _BookingStatusChart(data: bkStatus),
          const SizedBox(height: 20),
          _section('Ingresos por mes (últimos 6)'),
          if (monthlyRev.isNotEmpty) _RevenueLineChart(data: monthlyRev),
          const SizedBox(height: 20),
          _section('Usuarios registrados por mes'),
          if (monthlyUsers.isNotEmpty) _UsersBarChart(data: monthlyUsers),
          const SizedBox(height: 20),
          _section('Calidad de la plataforma'),
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricTile(
                    label: 'Rating promedio',
                    value: avgRating.toStringAsFixed(2),
                    icon: Icons.star,
                    color: Colors.amber,
                  ),
                  _MetricTile(
                    label: 'Total reseñas',
                    value: '$totalReviews',
                    icon: Icons.rate_review,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: AppTextStyles.heading3),
      );
}

class _ServicePieChart extends StatelessWidget {
  final Map<String, int> data;
  const _ServicePieChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.primary, AppColors.accent, Colors.purple];
    final labels = {
      'paseo': 'Paseo 🦮',
      'cuidado': 'Cuidado 🏠',
      'baño': 'Baño 🛁',
    };
    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: entries.asMap().entries.map((e) {
                    final pct =
                        total > 0 ? e.value.value / total * 100 : 0.0;
                    return PieChartSectionData(
                      color: colors[e.key % colors.length],
                      value: e.value.value.toDouble(),
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: 70,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              children: entries.asMap().entries.map((e) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: colors[e.key % colors.length],
                            shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(
                        '${labels[e.value.key] ?? e.value.key}: ${e.value.value}',
                        style: AppTextStyles.caption),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingStatusChart extends StatelessWidget {
  final Map<String, int> data;
  const _BookingStatusChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final labels = {
      'pending': 'Pendiente',
      'accepted': 'Aceptado',
      'in_progress': 'En progreso',
      'completed': 'Completado',
      'cancelled': 'Cancelado',
    };
    final colors = {
      'pending': Colors.orange,
      'accepted': AppColors.primary,
      'in_progress': Colors.purple,
      'completed': AppColors.success,
      'cancelled': AppColors.error,
    };
    final entries = data.entries.toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: entries.map((e) {
            final total = data.values.fold<int>(0, (s, v) => s + v);
            final pct = total > 0 ? e.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(labels[e.key] ?? e.key,
                              style: AppTextStyles.label)),
                      Text('${e.value}', style: AppTextStyles.label),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppColors.divider,
                    color: colors[e.key] ?? AppColors.primary,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _RevenueLineChart extends StatelessWidget {
  final Map<String, double> data;
  const _RevenueLineChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.toList();
    final spots = keys.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), data[e.value] ?? 0))
        .toList();
    final maxY = data.values.fold<double>(0, (a, b) => a > b ? a : b);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        child: SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: maxY <= 0 ? 10 : maxY * 1.2,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.success,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.success.withOpacity(0.15),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) => Text(
                      v >= 1000 ? '\$${(v / 1000).toStringAsFixed(0)}K' : '\$${v.toInt()}',
                      style: const TextStyle(fontSize: 9),
                    ),
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
                      const names = ['','Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(names[month], style: const TextStyle(fontSize: 10)),
                      );
                    },
                    reservedSize: 22,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UsersBarChart extends StatelessWidget {
  final Map<String, int> data;
  const _UsersBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final keys = data.keys.toList();
    final bars = keys.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: (data[e.value] ?? 0).toDouble(),
            color: AppColors.accent,
            width: 18,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    final maxY = (data.values.fold<int>(0, (a, b) => a > b ? a : b) + 2).toDouble();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 20, 12),
        child: SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              maxY: maxY < 4 ? 4 : maxY,
              barGroups: bars,
              gridData: const FlGridData(drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
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
                      const names = ['','Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(names[month], style: const TextStyle(fontSize: 10)),
                      );
                    },
                    reservedSize: 22,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricTile(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(value,
            style: AppTextStyles.heading2.copyWith(color: color)),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
