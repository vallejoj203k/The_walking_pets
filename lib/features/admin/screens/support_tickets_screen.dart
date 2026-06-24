import 'package:flutter/material.dart';
import '../../../core/models/support_ticket_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../widgets/custom_app_bar.dart';

class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  List<SupportTicketModel> _all = [];
  List<SupportTicketModel> _filtered = [];
  bool _loading = true;
  String? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.client
          .from('support_tickets')
          .select()
          .order('created_at', ascending: false);
      final tickets = (data as List)
          .map((e) => SupportTicketModel.fromMap(e))
          .toList();
      if (mounted) {
        setState(() {
          _all = tickets;
          _filtered = tickets;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    setState(() {
      _filtered = _statusFilter == null
          ? _all
          : _all.where((t) => t.status == _statusFilter).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              const Text('Estado: ',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              DropdownButton<String?>(
                value: _statusFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'open', child: Text('Abiertos')),
                  DropdownMenuItem(
                      value: 'in_progress', child: Text('En progreso')),
                  DropdownMenuItem(
                      value: 'resolved', child: Text('Resueltos')),
                  DropdownMenuItem(value: 'closed', child: Text('Cerrados')),
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
                  ? const Center(child: Text('Sin tickets.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) {
                          final t = _filtered[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: _PriorityIndicator(
                                  priority: t.priority),
                              title: Text(t.subject,
                                  style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                '${t.categoryLabel} · ${t.statusLabel} · ${_fmtDate(t.createdAt)}',
                                style: AppTextStyles.caption,
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      _TicketDetailScreen(ticket: t,
                                          onUpdate: _load),
                                ),
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

  String _fmtDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}

class _PriorityIndicator extends StatelessWidget {
  final String priority;
  const _PriorityIndicator({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case 'high': color = AppColors.error; break;
      case 'medium': color = AppColors.accent; break;
      default: color = AppColors.success;
    }
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(2)),
    );
  }
}

class _TicketDetailScreen extends StatefulWidget {
  final SupportTicketModel ticket;
  final VoidCallback onUpdate;
  const _TicketDetailScreen(
      {required this.ticket, required this.onUpdate});

  @override
  State<_TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<_TicketDetailScreen> {
  final _responseCtrl = TextEditingController();
  bool _saving = false;
  late String _currentStatus;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.ticket.status;
    _responseCtrl.text = widget.ticket.adminResponse ?? '';
  }

  @override
  void dispose() {
    _responseCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await SupabaseService.client
          .from('support_tickets')
          .update({
        'status': _currentStatus,
        'admin_response': _responseCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
        if (_currentStatus == 'resolved')
          'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.ticket.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket actualizado.')),
        );
        widget.onUpdate();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'Ticket de soporte'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        _chip(t.priorityLabel, _priorityColor(t.priority)),
                        const SizedBox(width: 8),
                        _chip(t.categoryLabel, AppColors.primary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(t.subject, style: AppTextStyles.heading3),
                    const SizedBox(height: 8),
                    Text(t.description, style: AppTextStyles.body),
                    const SizedBox(height: 8),
                    Text(
                      'Creado: ${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Estado', style: AppTextStyles.label),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _currentStatus,
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(value: 'open', child: Text('Abierto')),
                DropdownMenuItem(
                    value: 'in_progress', child: Text('En progreso')),
                DropdownMenuItem(
                    value: 'resolved', child: Text('Resuelto')),
                DropdownMenuItem(value: 'closed', child: Text('Cerrado')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _currentStatus = v);
              },
            ),
            const SizedBox(height: 16),
            Text('Respuesta al usuario', style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextFormField(
              controller: _responseCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Escribe tu respuesta aquí...',
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'high': return AppColors.error;
      case 'medium': return AppColors.accent;
      default: return AppColors.success;
    }
  }
}
