import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../location/providers/location_provider.dart';
import '../../services/screens/service_detail_screen.dart';
import '../../../core/services/supabase_service.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
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
  List<Map<String, dynamic>> _homes = [];

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
    _homes = homes;

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
      final walkerId = home['id'] as String;
      final name = home['name'] as String? ?? 'Paseador';
      markers.add(Marker(
        markerId: MarkerId('home_$walkerId'),
        position: LatLng(lat, lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: '🏠 $name', snippet: 'Toca para ver servicios'),
        onTap: () => _showWalkerSheet(walkerId, name),
      ));
    }

    // Paseadores activos en tiempo real (naranja)
    for (final walker in nearby) {
      final walkerId = walker.walkerId;
      // Buscar nombre en homes si existe
      final homeData = homes.where((h) => h['id'] == walkerId).toList();
      final name = homeData.isNotEmpty
          ? homeData.first['name'] as String? ?? 'Paseador activo'
          : 'Paseador activo';
      markers.add(Marker(
        markerId: MarkerId('live_$walkerId'),
        position: LatLng(walker.latitude, walker.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: InfoWindow(
          title: '🟠 $name',
          snippet: 'Activo · ${_timeAgo(walker.lastUpdated)}',
        ),
        onTap: () => _showWalkerSheet(walkerId, name),
      ));
    }

    if (mounted) setState(() => _markers = markers);
  }

  Future<void> _showWalkerSheet(String walkerId, String walkerName) async {
    // Traer servicios del paseador
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _WalkerServicesSheet(
        walkerId: walkerId,
        walkerName: walkerName,
      ),
    );
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMarkers),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendItem(color: Colors.green, label: 'Residencia'),
                  SizedBox(height: 4),
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

class _WalkerServicesSheet extends StatefulWidget {
  final String walkerId;
  final String walkerName;

  const _WalkerServicesSheet({
    required this.walkerId,
    required this.walkerName,
  });

  @override
  State<_WalkerServicesSheet> createState() => _WalkerServicesSheetState();
}

class _WalkerServicesSheetState extends State<_WalkerServicesSheet> {
  List<Map<String, dynamic>> _services = [];
  Map<String, dynamic> _walkerData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Datos del paseador
      final walkerResult = await SupabaseService.client
          .from('walkers')
          .select()
          .eq('id', widget.walkerId)
          .maybeSingle();

      // Servicios activos del paseador
      final servicesResult = await SupabaseService.client
          .from('services')
          .select()
          .eq('walker_id', widget.walkerId)
          .eq('is_active', true)
          .order('created_at');

      if (mounted) {
        setState(() {
          _walkerData = walkerResult ?? {'id': widget.walkerId, 'name': widget.walkerName};
          _services = List<Map<String, dynamic>>.from(servicesResult as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _emoji(String type) {
    switch (type) {
      case 'paseo': return '🦮';
      case 'cuidado': return '🏠';
      case 'baño': return '🛁';
      default: return '🐾';
    }
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _priceSummary(Map<String, dynamic> s) {
    final type = s['type'] as String? ?? '';
    final price = (s['price'] as num?)?.toDouble() ?? 0;
    final small = (s['price_small'] as num?)?.toDouble();
    final medium = (s['price_medium'] as num?)?.toDouble();
    final large = (s['price_large'] as num?)?.toDouble();

    if (type == 'baño') {
      final parts = <String>[];
      if (small != null) parts.add('Peq: \$${small.toStringAsFixed(0)}');
      if (medium != null) parts.add('Med: \$${medium.toStringAsFixed(0)}');
      if (large != null) parts.add('Gran: \$${large.toStringAsFixed(0)}');
      return parts.isEmpty ? 'Sin precio' : parts.join(' · ');
    }
    final unit = type == 'cuidado' ? '/día' : '/hora';
    return '\$${price.toStringAsFixed(0)} COP$unit';
  }

  @override
  Widget build(BuildContext context) {
    final photo = _walkerData['photo_url'] as String?;
    final experience = _walkerData['experience_years'] as int?;
    final zone = _walkerData['coverage_zone'] as String?;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Header del paseador
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: photo != null && photo.isNotEmpty
                                ? NetworkImage(photo)
                                : null,
                            child: photo == null || photo.isEmpty
                                ? const Icon(Icons.person, size: 32, color: AppColors.primary)
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.walkerName, style: AppTextStyles.heading2),
                                if (experience != null)
                                  Text('$experience años de experiencia',
                                      style: AppTextStyles.bodySecondary),
                                if (zone != null)
                                  Text('📍 $zone', style: AppTextStyles.bodySecondary),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Servicios disponibles', style: AppTextStyles.heading3),
                      const SizedBox(height: 12),
                      if (_services.isEmpty)
                        const Text('Este paseador no tiene servicios activos.',
                            style: TextStyle(color: AppColors.textSecondary))
                      else
                        ..._services.map((s) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Text(_emoji(s['type'] ?? ''),
                                style: const TextStyle(fontSize: 28)),
                            title: Text(_capitalize(s['type'] ?? ''),
                                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                            subtitle: Text(_priceSummary(s)),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ServiceDetailScreen(
                                      serviceData: {...s, 'walkers': _walkerData},
                                      walkerData: _walkerData,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: const Size(0, 34),
                              ),
                              child: const Text('Reservar'),
                            ),
                          ),
                        )),
                    ],
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
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
