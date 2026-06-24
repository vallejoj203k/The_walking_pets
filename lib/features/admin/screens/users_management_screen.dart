import 'package:flutter/material.dart';
import '../providers/admin_provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import 'user_detail_screen.dart';

class UsersManagementScreen extends StatefulWidget {
  final AdminProvider adminProvider;
  const UsersManagementScreen({super.key, required this.adminProvider});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _search = '';
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final u = await widget.adminProvider.getAllUsers();
    if (mounted) {
      setState(() {
        _users = u;
        _filtered = u;
        _loading = false;
      });
    }
  }

  void _filter() {
    setState(() {
      _filtered = _users.where((u) {
        final name = (u['name'] as String? ?? '').toLowerCase();
        final matchSearch =
            _search.isEmpty || name.contains(_search.toLowerCase());
        final matchType =
            _typeFilter == null || u['type'] == _typeFilter;
        return matchSearch && matchType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) {
                    _search = v;
                    _filter();
                  },
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _typeFilter,
                underline: const SizedBox(),
                hint: const Text('Tipo'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'walker', child: Text('Paseadores')),
                  DropdownMenuItem(value: 'owner', child: Text('Dueños')),
                ],
                onChanged: (v) {
                  _typeFilter = v;
                  _filter();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final u = _filtered[i];
                      final isWalker = u['type'] == 'walker';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
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
                              size: 20,
                            ),
                          ),
                          title: Text(u['name'] as String? ?? 'Sin nombre',
                              style: AppTextStyles.body
                                  .copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            isWalker
                                ? 'Paseador · ${u['coverage_zone'] ?? 'Sin zona'}'
                                : 'Dueño · ${u['city'] ?? 'Sin ciudad'}',
                            style: AppTextStyles.caption,
                          ),
                          trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: AppColors.textSecondary),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserDetailScreen(
                                userData: u,
                              ),
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
}
