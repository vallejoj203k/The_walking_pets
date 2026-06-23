import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/supabase_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/profile/screens/walker_profile_screen.dart';
import 'features/profile/screens/owner_profile_screen.dart';
import 'features/home/screens/walker_home_screen.dart';
import 'features/home/screens/owner_home_screen.dart';
import 'config/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const TheWalkingPetsApp());
}

class TheWalkingPetsApp extends StatelessWidget {
  const TheWalkingPetsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        title: 'The Walking Pets',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (_) => const SplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/register': (_) => const RegisterScreen(),
          '/role-selection': (_) => const RoleSelectionScreen(),
          '/walker-profile': (_) => const WalkerProfileScreen(),
          '/owner-profile': (_) => const OwnerProfileScreen(),
          '/walker-home': (_) => const WalkerHomeScreen(),
          '/owner-home': (_) => const OwnerHomeScreen(),
        },
      ),
    );
  }
}
