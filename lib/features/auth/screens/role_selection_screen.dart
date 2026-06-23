import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/role_card.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants/app_constants.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  Future<void> _register() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un rol'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final email = args['email'] as String;
    final password = args['password'] as String;

    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      email: email,
      password: password,
      role: _selectedRole!,
    );

    if (!mounted) return;

    if (success) {
      if (_selectedRole == AppConstants.roleWalker) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/walker-profile', (r) => false);
      } else {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/owner-profile', (r) => false);
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('¿Cómo quieres usar\nThe Walking Pets?',
                  style: AppTextStyles.heading1),
              const SizedBox(height: 8),
              Text('Selecciona tu rol para personalizar tu experiencia',
                  style: AppTextStyles.bodySecondary),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: RoleCard(
                      title: 'Paseador',
                      description:
                          'Ofrece tus servicios de paseo y cuidado de mascotas',
                      icon: Icons.directions_walk,
                      selected: _selectedRole == AppConstants.roleWalker,
                      onTap: () =>
                          setState(() => _selectedRole = AppConstants.roleWalker),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RoleCard(
                      title: 'Dueño',
                      description:
                          'Encuentra paseadores confiables para tus mascotas',
                      icon: Icons.favorite,
                      selected: _selectedRole == AppConstants.roleOwner,
                      onTap: () =>
                          setState(() => _selectedRole = AppConstants.roleOwner),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              CustomElevatedButton(
                label: 'Crear cuenta',
                onPressed: _register,
                isLoading: auth.isLoading,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
