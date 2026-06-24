import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import 'admin_dashboard_screen.dart';
import 'analytics_screen.dart';
import 'users_management_screen.dart';
import 'transactions_admin_screen.dart';
import 'support_tickets_screen.dart';
import 'platform_settings_screen.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dashboard, label: 'Dashboard'),
    _NavItem(icon: Icons.bar_chart, label: 'Analytics'),
    _NavItem(icon: Icons.people, label: 'Usuarios'),
    _NavItem(icon: Icons.receipt_long, label: 'Transacciones'),
    _NavItem(icon: Icons.support_agent, label: 'Soporte'),
    _NavItem(icon: Icons.settings, label: 'Configuración'),
  ];

  @override
  Widget build(BuildContext context) {
    final admin = context.read<AdminProvider>();
    final auth = context.read<AuthProvider>();

    final screens = [
      AdminDashboardScreen(adminProvider: admin),
      AnalyticsScreen(adminProvider: admin),
      UsersManagementScreen(adminProvider: admin),
      TransactionsAdminScreen(adminProvider: admin),
      const SupportTicketsScreen(),
      PlatformSettingsScreen(adminProvider: admin),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        title: Text(_navItems[_selectedIndex].label,
            style: AppTextStyles.heading3.copyWith(color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              admin.reset();
              context.read<ProfileProvider>().clear();
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration:
                  const BoxDecoration(color: AppColors.primaryDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 10),
                  Text('Admin Panel',
                      style: AppTextStyles.heading3
                          .copyWith(color: Colors.white)),
                  Text(
                    admin.adminRole == 'super_admin'
                        ? 'Super Administrador'
                        : admin.adminRole == 'moderator'
                            ? 'Moderador'
                            : 'Soporte',
                    style: AppTextStyles.bodySecondary
                        .copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: _navItems.asMap().entries.map((e) {
                  final selected = _selectedIndex == e.key;
                  return ListTile(
                    leading: Icon(
                      e.value.icon,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    title: Text(
                      e.value.label,
                      style: TextStyle(
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    selected: selected,
                    selectedTileColor: AppColors.primaryLight,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      setState(() => _selectedIndex = e.key);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: AppColors.surface,
        destinations: _navItems
            .map((n) => NavigationDestination(
                  icon: Icon(n.icon),
                  label: n.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
