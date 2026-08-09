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

  final initError = await _initializeServices();
  if (initError != null) {
    runApp(StartupErrorApp(message: initError));
    return;
  }

  runApp(const TheWalkingPetsApp());
}

/// Inicializa los servicios de la app.
///
/// Devuelve `null` si todo salió bien, o un mensaje para el usuario si falló
/// algo sin lo cual la app no puede funcionar. Los servicios opcionales
/// (formatos de fecha, Firebase, notificaciones) nunca tumban el arranque:
/// si fallan se registra el error y la app sigue abriendo.
Future<String?> _initializeServices() async {
  try {
    await initializeDateFormatting('es', null);
  } catch (e) {
    debugPrint('[init] Formato de fechas falló: $e');
  }

  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('[init] Supabase falló: $e');
    return 'No pudimos conectarnos al servidor.\n\n'
        'Revisa tu conexión a internet e intenta de nuevo.';
  }

  // Sin notificaciones push la app funciona igual, así que un fallo aquí
  // no debe impedir que el usuario entre.
  try {
    await Firebase.initializeApp();
    await NotificationService.instance.initialize();
  } catch (e) {
    debugPrint('[init] Firebase/notificaciones falló: $e');
  }

  return null;
}

/// Pantalla que se muestra cuando la app no pudo arrancar, en lugar de
/// cerrarse sin explicación.
class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: main,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
