import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../../location/providers/location_provider.dart';
import '../../../core/models/booking_model.dart';
import '../widgets/booking_status_badge.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants/maps_config.dart';

class BookingDetailScreen extends StatefulWidget {
  final BookingModel booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  GoogleMapController? _mapCtrl;
  StreamSubscription? _locationSub;
  LatLng? _walkerLatLng;
  Set<Marker> _markers = {};

  bool get _isInProgress =>
      widget.booking.status == 'in_progress';

  @override
  void initState() {
    super.initState();
    if (_isInProgress) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _watchLocation());
    }
  }

  void _watchLocation() {
    final stream = context
        .read<LocationProvider>()
        .watchWalkerLocation(widget.booking.walkerId);

    _locationSub = stream.listen((data) {
      if (data.isEmpty || !mounted) return;
      final loc = data.first;
      final lat = (loc['latitude'] as num?)?.toDouble();
      final lng = (loc['longitude'] as num?)?.toDouble();
      if (lat == null || lng == null) return;

      setState(() {
        _walkerLatLng = LatLng(lat, lng);
        _markers = {
          Marker(
            markerId: const MarkerId('walker'),
            position: _walkerLatLng!,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
            infoWindow: InfoWindow(
                title: 'Paseador: ${widget.booking.walkerName ?? ''}'),
          ),
        };
      });

      _mapCtrl?.animateCamera(
        CameraUpdate.newLatLng(_walkerLatLng!),
      );
    });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');
    final b = widget.booking;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Detalle de reserva'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Estado', style: AppTextStyles.label),
                BookingStatusBadge(status: b.status),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _InfoRow('Paseador', b.walkerName ?? '-'),
                    _InfoRow('Mascota', b.petName ?? '-'),
                    _InfoRow('Servicio',
                        b.serviceType != null
                            ? _capitalize(b.serviceType!)
                            : '-'),
                    if (b.servicePrice != null)
                      _InfoRow('Precio',
                          '\$${b.servicePrice!.toStringAsFixed(0)} COP/h'),
                    _InfoRow('Fecha', fmt.format(b.scheduledDate)),
                    if (b.notes != null && b.notes!.isNotEmpty)
                      _InfoRow('Notas', b.notes!),
                  ],
                ),
              ),
            ),

            if (_isInProgress) ...[
              const SizedBox(height: 20),
              Text('Ubicación en tiempo real',
                  style: AppTextStyles.heading3),
              const SizedBox(height: 8),
              _walkerLatLng == null
                  ? Container(
                      height: 200,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Esperando ubicación del paseador...'),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 280,
                        child: GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _walkerLatLng!,
                            zoom: 15,
                          ),
                          onMapCreated: (ctrl) => _mapCtrl = ctrl,
                          markers: _markers,
                          zoomControlsEnabled: false,
                        ),
                      ),
                    ),
            ],

            const SizedBox(height: 24),
            if (b.canCancel)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await context
                        .read<BookingProvider>()
                        .updateBookingStatus(b.id, 'cancelled');
                    if (mounted) Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Cancelar reserva'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: AppTextStyles.bodySecondary),
          ),
          Expanded(
            child: Text(value, style: AppTextStyles.body),
          ),
        ],
      ),
    );
  }
}
