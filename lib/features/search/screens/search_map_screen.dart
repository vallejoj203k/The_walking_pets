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

    final markers = <Marker>{};

    // Marcador del usuario
    markers.add(Marker(
      markerId: const MarkerId('me'),
      position: LatLng(
          locationProvider.currentLat, locationProvider.currentLng),
      icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueBlue),
      infoWindow: const InfoWindow(title: 'Mi ubicación'),
    ));

    // Marcadores de paseadores
    for (final walker in nearby) {
      markers.add(Marker(
        markerId: MarkerId(walker.walkerId),
        position: LatLng(walker.latitude, walker.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: 'Paseador',
          snippet:
              'Actualizado: ${_timeAgo(walker.lastUpdated)}',
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
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_markers.where((m) => m.markerId.value != 'me').length} paseadores cercanos',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
