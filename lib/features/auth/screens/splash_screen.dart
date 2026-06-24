import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    if (authProvider.status == AuthStatus.initial) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _navigate(authProvider);
  }

  void _navigate(AuthProvider authProvider) {
    if (!mounted) return;
    if (authProvider.isAuthenticated && authProvider.userModel != null) {
      if (authProvider.userModel!.email == AppConstants.adminEmail) {
        Navigator.of(context).pushReplacementNamed('/admin-home');
        return;
      }
      final role = authProvider.userModel!.role;
      if (role == AppConstants.roleWalker) {
        Navigator.of(context).pushReplacementNamed('/walker-home');
      } else {
        Navigator.of(context).pushReplacementNamed('/owner-home');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child:
                  const Icon(Icons.pets, size: 60, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              AppConstants.appName,
              style: AppTextStyles.heading1.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'El paseo de tus mascotas, sin estrés',
              style: AppTextStyles.body
                  .copyWith(color: Colors.white.withOpacity(0.85)),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
