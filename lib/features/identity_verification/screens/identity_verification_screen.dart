import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/identity_verification_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  final _picker = ImagePicker();
  File? _cedulaFront;
  File? _cedulaBack;
  File? _selfie;
  int _step = 0; // 0: cédula frente, 1: cédula reverso, 2: selfie

  bool get _canSubmit =>
      _cedulaFront != null && _cedulaBack != null && _selfie != null;

  Future<void> _pickImage(ImageSource source, int photoType) async {
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked == null) return;
    final file = File(picked.path);
    setState(() {
      if (photoType == 0) _cedulaFront = file;
      if (photoType == 1) _cedulaBack = file;
      if (photoType == 2) _selfie = file;
      if (_step == photoType) _step = (photoType + 1).clamp(0, 2);
    });
  }

  void _showImageSourceSheet(int photoType) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, photoType);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Elegir de galería'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, photoType);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final userId = context.read<AuthProvider>().userModel!.id;
    final provider = context.read<IdentityVerificationProvider>();

    final approved = await provider.submitVerification(
      userId: userId,
      cedulaFront: _cedulaFront!,
      cedulaBack: _cedulaBack!,
      selfie: _selfie!,
    );

    if (!mounted) return;

    if (approved) {
      Navigator.of(context).pushNamedAndRemoveUntil('/walker-home', (r) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Identidad verificada! Bienvenido a The Walking Pets.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final reason = provider.rejectionReason ??
          'No se pudo verificar tu identidad. Intenta de nuevo.';
      _showRejectionDialog(reason);
    }
  }

  void _showRejectionDialog(String reason) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Verificación fallida'),
        content: Text(reason),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<IdentityVerificationProvider>().reset();
              setState(() {
                _cedulaFront = null;
                _cedulaBack = null;
                _selfie = null;
                _step = 0;
              });
            },
            child: const Text('Intentar de nuevo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IdentityVerificationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Verificación de identidad',
        showBack: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Verifica tu identidad', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              'Para garantizar la seguridad de nuestros usuarios, necesitamos verificar tu identidad antes de que puedas ofrecer servicios.',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 32),

            // Step indicator
            _StepIndicator(current: _step),
            const SizedBox(height: 32),

            // Cédula frente
            _PhotoCard(
              title: 'Cédula — Frente',
              subtitle: 'Foto de la parte frontal de tu cédula de ciudadanía',
              icon: Icons.credit_card,
              file: _cedulaFront,
              isActive: _step == 0,
              onTap: provider.isLoading ? null : () => _showImageSourceSheet(0),
            ),
            const SizedBox(height: 16),

            // Cédula reverso
            _PhotoCard(
              title: 'Cédula — Reverso',
              subtitle: 'Foto de la parte trasera de tu cédula de ciudadanía',
              icon: Icons.credit_card_outlined,
              file: _cedulaBack,
              isActive: _step == 1,
              onTap: provider.isLoading ? null : () => _showImageSourceSheet(1),
            ),
            const SizedBox(height: 16),

            // Selfie
            _PhotoCard(
              title: 'Selfie',
              subtitle: 'Foto de tu rostro. Asegúrate de que haya buena iluminación y tu cara sea visible.',
              icon: Icons.face,
              file: _selfie,
              isActive: _step == 2,
              onTap: provider.isLoading ? null : () => _showImageSourceSheet(2),
            ),
            const SizedBox(height: 32),

            if (provider.status == VerificationStatus.uploading)
              _StatusBanner(
                message: 'Subiendo imágenes...',
                icon: Icons.cloud_upload_outlined,
                color: AppColors.primary,
              ),
            if (provider.status == VerificationStatus.verifying)
              _StatusBanner(
                message: 'Verificando identidad con IA...',
                icon: Icons.psychology_outlined,
                color: AppColors.primary,
              ),

            const SizedBox(height: 8),
            CustomElevatedButton(
              label: 'Verificar identidad',
              isLoading: provider.isLoading,
              onPressed: (_canSubmit && !provider.isLoading) ? _submit : null,
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Tus datos son cifrados y usados únicamente para verificación.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  const _StepIndicator({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Dot(label: '1', done: current > 0, active: current == 0),
        _Line(done: current > 0),
        _Dot(label: '2', done: current > 1, active: current == 1),
        _Line(done: current > 1),
        _Dot(label: '3', done: current > 2, active: current == 2),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;
  const _Dot({required this.label, required this.done, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.success
        : active
            ? AppColors.primary
            : AppColors.textSecondary.withOpacity(0.3);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Center(
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final bool done;
  const _Line({required this.done});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        color: done ? AppColors.success : AppColors.textSecondary.withOpacity(0.2),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final File? file;
  final bool isActive;
  final VoidCallback? onTap;

  const _PhotoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.file,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = file != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPhoto
                ? AppColors.success
                : isActive
                    ? AppColors.primary
                    : AppColors.textSecondary.withOpacity(0.2),
            width: hasPhoto || isActive ? 2 : 1,
          ),
        ),
        child: hasPhoto
            ? ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  children: [
                    Image.file(file!,
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 16),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        color: Colors.black54,
                        child: Text(title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.primaryLight
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon,
                          color: isActive
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: AppTextStyles.bodySecondary.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 4),
                          Text(subtitle, style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;

  const _StatusBanner({
    required this.message,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: color),
          ),
          const SizedBox(width: 12),
          Text(message, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
