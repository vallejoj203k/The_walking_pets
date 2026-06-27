import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/profile/providers/profile_provider.dart';
import 'features/services/providers/services_provider.dart';
import 'features/booking/providers/booking_provider.dart';
import 'features/location/providers/location_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/reviews/providers/reviews_provider.dart';
import 'features/payments/providers/payment_provider.dart';
import 'features/admin/providers/admin_provider.dart';
import 'features/identity_verification/providers/identity_verification_provider.dart';
import 'features/identity_verification/screens/identity_verification_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/role_selection_screen.dart';
import 'features/profile/screens/walker_profile_screen.dart';
import 'features/profile/screens/owner_profile_screen.dart';
import 'features/home/screens/walker_home_screen.dart';
import 'features/home/screens/owner_home_screen.dart';
import 'features/admin/screens/admin_home_screen.dart';
import 'config/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await SupabaseService.initialize();
  await Firebase.initializeApp();
  await NotificationService.instance.initialize();
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
        ChangeNotifierProvider(create: (_) => ServicesProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ReviewsProvider()),
        ChangeNotifierProvider(create: (_) => PaymentProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => IdentityVerificationProvider()),
      ],
      child: MaterialApp(
        title: 'The Walking Pets',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        locale: const Locale('es'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es'),
          Locale('en'),
        ],
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
          '/admin-home': (_) => const AdminHomeScreen(),
          '/identity-verification': (_) => const IdentityVerificationScreen(),
        },
      ),
    );
  }
}
