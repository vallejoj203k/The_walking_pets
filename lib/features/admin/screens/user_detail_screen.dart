import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../widgets/custom_app_bar.dart';

class UserDetailScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const UserDetailScreen({super.key, required this.userData});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _reviews = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isWalker = widget.userData['type'] == 'walker';
    final id = widget.userData['id'] as String;
    try {
      final results = await Future.wait([
        SupabaseService.client
            .from('bookings')
            .select('id, status, scheduled_date, created_at')
            .eq(isWalker ? 'walker_id' : 'owner_id', id)
            .order('created_at', ascending: false)
            .limit(10),
        if (isWalker)
          SupabaseService.client
              .from('reviews')
              .select('rating, comment, created_at')
              .eq('walker_id', id)
              .order('created_at', ascending: false)
              .limit(10)
        else
          Future.value([]),
      ]);
      if (mounted) {
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(results[0] as List);
          _reviews = List<Map<String, dynamic>>.from(results[1] as List);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.userData['name'] as String? ?? 'Usuario';
    final isWalker = widget.userData['type'] == 'walker';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: name),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: isWalker
                                    ? AppColors.primaryLight
                                    : AppColors.accentLight,
                                child: Icon(
                                  isWalker
                                      ? Icons.directions_walk
                                      : Icons.person,
                                  color: isWalker
                                      ? AppColors.primary
                                      : AppColors.accent,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: AppTextStyles.heading3),
                                    Text(
                                      isWalker ? 'Paseador' : 'Dueño de mascotas',
                                      style: AppTextStyles.bodySecondary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (isWalker && widget.userData['coverage_zone'] != null)
                            _infoRow(Icons.location_on, 'Zona',
                                widget.userData['coverage_zone'] as String),
                          if (!isWalker && widget.userData['city'] != null)
                            _infoRow(Icons.location_city, 'Ciudad',
                                widget.userData['city'] as String),
                          if (widget.userData['created_at'] != null)
                            _infoRow(
                                Icons.calendar_today,
                                'Registrado',
                                _fmtDate(
                                    widget.userData['created_at'] as String)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bookings
                  Text('Últimas reservas (${_bookings.length})',
                      style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  if (_bookings.isEmpty)
                    const Text('Sin reservas.',
                        style: TextStyle(color: AppColors.textSecondary))
                  else
                    ..._bookings.map((b) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            leading: _statusIcon(b['status'] as String? ?? ''),
                            title: Text(_statusLabel(b['status'] as String? ?? ''),
                                style: AppTextStyles.body),
                            subtitle: Text(
                                _fmtDate(b['scheduled_date'] as String? ??
                                    b['created_at'] as String),
                                style: AppTextStyles.caption),
                          ),
                        )),

                  // Reviews (only walkers)
                  if (isWalker && _reviews.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text('Últimas reseñas', style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    ..._reviews.map((r) => Card(
                          margin: const EdgeInsets.only(bottom: 6),
                          child: ListTile(
                            leading: Text('⭐ ${r['rating']}',
                                style: const TextStyle(fontSize: 18)),
                            title: Text(
                                r['comment'] as String? ?? 'Sin comentario',
                                style: AppTextStyles.body),
                            subtitle: Text(
                                _fmtDate(r['created_at'] as String),
                                style: AppTextStyles.caption),
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$label: ', style: AppTextStyles.label),
          Expanded(child: Text(value, style: AppTextStyles.body)),
        ],
      ),
    );
  }

  Widget _statusIcon(String status) {
    Color color;
    switch (status) {
      case 'completed': color = AppColors.success; break;
      case 'cancelled': color = AppColors.error; break;
      case 'in_progress': color = Colors.purple; break;
      default: color = AppColors.accent;
    }
    return CircleAvatar(
        radius: 14, backgroundColor: color.withOpacity(0.15),
        child: Icon(Icons.event, size: 16, color: color));
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending': return 'Pendiente';
      case 'accepted': return 'Aceptado';
      case 'in_progress': return 'En progreso';
      case 'completed': return 'Completado';
      case 'cancelled': return 'Cancelado';
      default: return s;
    }
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
