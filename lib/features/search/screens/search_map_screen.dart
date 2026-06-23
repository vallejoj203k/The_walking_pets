import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../location/providers/location_provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/constants/maps_config.dart';

class SearchMapScreen extends StatefulWidget {
  const SearchMapScreen({super.key});

  @override
  State<SearchMapScreen> createState() => _SearchMapScreenState();
}

class _SearchMapScreenState extends State<SearchMapScreen> {
  GoogleMapController? _mapCtrl;
  final Completer<GoogleMapController> _mapCompleter = Completer();
  Set<Marker> _markers = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locationProvider = context.read<LocationProvider>();
      await locationProvider.initialize();
      _mapCtrl = await _mapCompleter.future;
      _moveToCurrentLocation(locationProvider);
      _loadMarkers();
      _refreshTimer = Timer.periodic(
        const Duration(seconds: MapsConfig.locationUpdateIntervalSeconds),
        (_) => _loadMarkers(),
      );
    });
  }

  void _moveToCurrentLocation(LocationProvider locationProvider) {
    _mapCtrl?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(locationProvider.currentLat, locationProvider.currentLng),
          zoom: 14,
        ),
      ),
    );
  }

  Future<void> _loadMarkers() async {
    if (!mounted) return;
    final locationProvider = context.read<LocationProvider>();
    final nearby = await locationProvider.getNearbyWalkers();
    final homes = await locationProvider.getWalkerHomes();

    final markers = <Marker>{};

    // Marcador del usuario (azul)
    markers.add(Marker(
      markerId: const MarkerId('me'),
      position: LatLng(locationProvider.currentLat, locationProvider.currentLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: 'Mi ubicación'),
    ));

    // Residencias de paseadores (verde)
    for (final home in homes) {
      final lat = (home['home_lat'] as num).toDouble();
      final lng = (home['home_lng'] as num).toDouble();
      final name = home['name'] as String? ?? 'Paseador';
      markers.add(Marker(
        markerId: MarkerId('home_${home['id']}'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: '🏠 $name',
          snippet: 'Residencia del paseador',
        ),
      ));
    }

    // Paseadores activos en tiempo real (naranja)
    for (final walker in nearby) {
      markers.add(Marker(
        markerId: MarkerId('live_${walker.walkerId}'),
        position: LatLng(walker.latitude, walker.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: '🟠 Paseador activo',
          snippet: 'Actualizado: ${_timeAgo(walker.lastUpdated)}',
        ),
      ));
    }

    if (mounted) setState(() => _markers = markers);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}min';
    return 'hace ${diff.inHours}h';
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Paseadores'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMarkers,
          ),
        ],
      ),
      body: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(MapsConfig.defaultLat, MapsConfig.defaultLng),
                    zoom: 13,
                  ),
                  onMapCreated: (ctrl) {
                    _mapCtrl = ctrl;
                    if (!_mapCompleter.isCompleted) _mapCompleter.complete(ctrl);
                  },
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: true,
                ),
                if (location.isLoading)
                  const Center(child: CircularProgressIndicator()),
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendItem(color: Colors.green, label: 'Residencia'),
                        const SizedBox(height: 4),
                        _LegendItem(color: Colors.orange, label: 'Activo ahora'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
