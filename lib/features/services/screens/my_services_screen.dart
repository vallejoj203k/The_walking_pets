import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/services_provider.dart';
import '../widgets/service_card.dart';
import 'create_service_screen.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../config/theme/app_colors.dart';

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final walkerId =
        context.read<AuthProvider>().userModel!.id;
    // We need the walker's profile id, not user id
    // Load via supabase directly using user_id
    await context.read<ServicesProvider>().loadMyServicesByUserId(walkerId);
  }

  Future<void> _deleteService(String serviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: const Text('¿Seguro que quieres eliminar este servicio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<ServicesProvider>().deleteService(serviceId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = context.watch<ServicesProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Mis Servicios', showBack: false),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CreateServiceScreen()),
          );
          _load();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuevo servicio'),
        backgroundColor: AppColors.primary,
      ),
      body: services.isLoading
          ? const Center(child: CircularProgressIndicator())
          : services.myServices.isEmpty
              ? EmptyState(
                  message:
                      'Aún no tienes servicios.\nCrea uno para que los dueños puedan contratarte.',
                  icon: Icons.home_repair_service_outlined,
                  actionLabel: '+ Crear servicio',
                  onAction: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateServiceScreen()),
                    );
                    _load();
                  },
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: services.myServices.length,
                    itemBuilder: (_, i) {
                      final service = services.myServices[i];
                      return ServiceCard(
                        service: service,
                        onToggleActive: (val) =>
                            services.toggleServiceActive(service.id, val),
                        onEdit: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CreateServiceScreen(service: service),
                            ),
                          );
                          _load();
                        },
                        onDelete: () => _deleteService(service.id),
                      );
                    },
                  ),
                ),
    );
  }
}
