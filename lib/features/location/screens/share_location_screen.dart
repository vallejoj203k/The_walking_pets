import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../../../core/services/supabase_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class ShareLocationScreen extends StatefulWidget {
  const ShareLocationScreen({super.key});

  @override
  State<ShareLocationScreen> createState() => _ShareLocationScreenState();
}

class _ShareLocationScreenState extends State<ShareLocationScreen> {
  String? _walkerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWalkerId());
  }

  Future<void> _loadWalkerId() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().userModel!.id;
    final data = await SupabaseService.client
        .from('walkers')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();
    if (mounted) setState(() => _walkerId = data?['id'] as String?);
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
          title: 'Compartir Ubicación', showBack: false),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: location.isSharing
                    ? AppColors.success.withOpacity(0.15)
                    : AppColors.inputFill,
                border: Border.all(
                  color: location.isSharing
                      ? AppColors.success
                      : AppColors.inputBorder,
                  width: 3,
                ),
              ),
              child: Icon(
                location.isSharing
                    ? Icons.location_on
                    : Icons.location_off,
                size: 56,
                color: location.isSharing
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              location.isSharing
                  ? 'Compartiendo ubicación'
                  : 'Ubicación desactivada',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              location.isSharing
                  ? 'Los dueños pueden ver tu posición en tiempo real durante el servicio.'
                  : 'Activa el seguimiento para que los dueños sepan dónde estás durante el paseo.',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            if (location.currentPosition != null) ...[
              const SizedBox(height: 12),
              Text(
                '📍 ${location.currentPosition!.latitude.toStringAsFixed(5)}, '
                '${location.currentPosition!.longitude.toStringAsFixed(5)}',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _walkerId == null
                    ? null
                    : () async {
                        if (location.isSharing) {
                          await location.stopSharingLocation();
                        } else {
                          await location.startSharingLocation(_walkerId!);
                        }
                      },
                icon: Icon(location.isSharing
                    ? Icons.stop
                    : Icons.play_arrow),
                label: Text(location.isSharing
                    ? 'Detener seguimiento'
                    : 'Iniciar seguimiento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: location.isSharing
                      ? AppColors.error
                      : AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
