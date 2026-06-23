import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/providers/profile_provider.dart';
import '../../profile/screens/owner_profile_screen.dart';
import '../../search/screens/search_screen.dart';
import '../../search/screens/search_map_screen.dart';
import '../../booking/screens/my_bookings_screen.dart';
import '../widgets/custom_bottom_nav.dart';
import '../../../widgets/empty_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      const _OwnerHomeTab(),
      const SearchScreen(),
      const MyBookingsScreen(),
      const OwnerProfileScreen(isEditing: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Buscar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Reservas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

class _OwnerHomeTab extends StatelessWidget {
  const _OwnerHomeTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>();
    final owner = profile.owner;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        title: const Text('The Walking Pets'),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const SearchMapScreen()),
            ),
            tooltip: 'Mapa de paseadores',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              profile.clear();
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (r) => false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: AppColors.accent,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¡Hola, ${owner?.name ?? auth.userModel?.email ?? ''}!',
                    style: AppTextStyles.heading2
                        .copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${profile.pets.length} mascota${profile.pets.length != 1 ? 's' : ''} registrada${profile.pets.length != 1 ? 's' : ''}',
                    style: AppTextStyles.body.copyWith(
                        color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Accesos rápidos', style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _QuickCard(
                        icon: Icons.search,
                        label: 'Buscar\nPaseadores',
                        color: AppColors.accent,
                        onTap: () {},
                      ),
                      const SizedBox(width: 12),
                      _QuickCard(
                        icon: Icons.map,
                        label: 'Ver en\nMapa',
                        color: AppColors.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SearchMapScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Mis mascotas', style: AppTextStyles.heading3),
                  const SizedBox(height: 12),
                  if (profile.pets.isEmpty)
                    const EmptyState(
                      message:
                          'Agrega mascotas desde tu perfil para hacer reservas.',
                      icon: Icons.pets,
                    )
                  else
                    ...profile.pets.map((pet) => ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.accentLight,
                            child: Text(pet.typeEmoji),
                          ),
                          title: Text(pet.name),
                          subtitle: Text(
                              '${_capitalize(pet.type)} · ${_capitalize(pet.size)}'),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(height: 8),
                Text(label,
                    style: AppTextStyles.label,
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
