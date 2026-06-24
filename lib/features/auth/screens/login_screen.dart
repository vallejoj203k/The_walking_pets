import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../admin/providers/admin_provider.dart';
import '../widgets/auth_text_field.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.login(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
    );

    if (!mounted) return;

    if (success && auth.userModel != null) {
      final userId = auth.userModel!.id;
      final isAdmin =
          await context.read<AdminProvider>().checkAdminStatus(userId);
      if (!mounted) return;
      if (isAdmin) {
        Navigator.of(context).pushReplacementNamed('/admin-home');
        return;
      }
      final role = auth.userModel!.role;
      if (role == 'walker') {
        Navigator.of(context).pushReplacementNamed('/walker-home');
      } else {
        Navigator.of(context).pushReplacementNamed('/owner-home');
      }
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.pets,
                        size: 40, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 32),
                Text('¡Bienvenido!', style: AppTextStyles.heading1),
                const SizedBox(height: 4),
                Text('Inicia sesión para continuar',
                    style: AppTextStyles.bodySecondary),
                const SizedBox(height: 32),
                AuthTextField(
                  label: 'Correo electrónico',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  label: 'Contraseña',
                  controller: _passwordCtrl,
                  isPassword: true,
                  validator: Validators.password,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _login,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {}, // TODO: Fase 2
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                const SizedBox(height: 8),
                CustomElevatedButton(
                  label: 'Iniciar sesión',
                  onPressed: _login,
                  isLoading: auth.isLoading,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿No tienes cuenta?  ',
                        style: AppTextStyles.bodySecondary),
                    GestureDetector(
                      onTap: () =>
                          Navigator.of(context).pushNamed('/register'),
                      child: Text(
                        'Regístrate',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
