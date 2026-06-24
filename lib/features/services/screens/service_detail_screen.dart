import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/services_provider.dart';
import '../../booking/screens/booking_screen.dart';
import '../../../core/models/service_model.dart';
import '../../../core/models/walker_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../widgets/service_card.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class ServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> serviceData;
  final Map<String, dynamic> walkerData;

  const ServiceDetailScreen({
    super.key,
    required this.serviceData,
    required this.walkerData,
  });

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  List<ServiceModel> _allServices = [];
  WalkerModel? _walker;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final walkerId = widget.walkerData['id'] as String;

      // Load full walker profile
      final walkerData = await SupabaseService.client
          .from('walkers')
          .select()
          .eq('id', walkerId)
          .single();
      _walker = WalkerModel.fromMap(walkerData);

      // Load all active services of this walker
      await context
          .read<ServicesProvider>()
          .loadWalkerServices(walkerId);
      _allServices = context.read<ServicesProvider>().walkerServices;
    } catch (e) {
      // fallback
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.walkerData['name'] as String? ?? 'Paseador';
    final photo = widget.walkerData['photo_url'] as String?;
    final experience = widget.walkerData['experience_years'] as int?;
    final zone = widget.walkerData['coverage_zone'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: name),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Walker header
                  Container(
                    width: double.infinity,
                    color: AppColors.primary,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primaryLight,
                          backgroundImage:
                              photo != null && photo.isNotEmpty
                                  ? CachedNetworkImageProvider(photo)
                                  : null,
                          child: photo == null || photo.isEmpty
                              ? const Icon(Icons.person,
                                  size: 44, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(name,
                            style: AppTextStyles.heading2
                                .copyWith(color: Colors.white)),
                        if (experience != null)
                          Text('$experience años de experiencia',
                              style: AppTextStyles.body.copyWith(
                                  color:
                                      Colors.white.withOpacity(0.85))),
                        if (zone != null)
                          Text('📍 $zone',
                              style: AppTextStyles.body.copyWith(
                                  color:
                                      Colors.white.withOpacity(0.85))),
                      ],
                    ),
                  ),

                  // Services
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Servicios disponibles',
                            style: AppTextStyles.heading3),
                        const SizedBox(height: 12),
                        if (_allServices.isEmpty)
                          const Text(
                              'Este paseador no tiene servicios activos.')
                        else
                          ..._allServices.map((s) => _ServiceOption(
                                service: s,
                                walker: _walker,
                              )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _ServiceOption extends StatelessWidget {
  final ServiceModel service;
  final WalkerModel? walker;

  const _ServiceOption({required this.service, this.walker});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(service.typeEmoji,
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.typeLabel,
                          style: AppTextStyles.heading3),
                      Text(service.priceSummary,
                          style: AppTextStyles.body
                              .copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
              ],
            ),
            if (service.description != null &&
                service.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(service.description!,
                  style: AppTextStyles.bodySecondary),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: walker != null
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(
                              service: service,
                              walker: walker!,
                            ),
                          ),
                        )
                    : null,
                child: const Text('Contratar este servicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
