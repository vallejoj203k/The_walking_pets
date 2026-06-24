import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../features/services/providers/services_provider.dart';
import '../../../features/services/screens/service_detail_screen.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants/app_constants.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  String? _filterType;
  double? _maxPrice;
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  Future<void> _search() async {
    setState(() => _isLoading = true);
    final results = await context.read<ServicesProvider>().searchWalkers(
          serviceType: _filterType,
          maxPrice: _maxPrice,
        );

    // Filtrar por nombre si hay texto
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _results = query.isEmpty
          ? results
          : results.where((r) {
              final walker = r['walkers'] as Map<String, dynamic>?;
              final name = (walker?['name'] as String? ?? '').toLowerCase();
              return name.contains(query);
            }).toList();
      _isLoading = false;
    });
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filtros', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              Text('Tipo de servicio', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _filterType == null,
                    onSelected: (_) =>
                        setModal(() => _filterType = null),
                  ),
                  ...AppConstants.walkerServices.map((t) => ChoiceChip(
                        label: Text(_capitalize(t)),
                        selected: _filterType == t,
                        selectedColor: AppColors.primaryLight,
                        onSelected: (_) =>
                            setModal(() => _filterType = t),
                      )),
                ],
              ),
              const SizedBox(height: 16),
              Text('Precio máximo por hora', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [null, 20000.0, 40000.0, 60000.0, 100000.0]
                    .map((p) => ChoiceChip(
                          label: Text(p == null
                              ? 'Sin límite'
                              : '\$${p.toStringAsFixed(0)}'),
                          selected: _maxPrice == p,
                          selectedColor: AppColors.primaryLight,
                          onSelected: (_) =>
                              setModal(() => _maxPrice = p),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _search();
                },
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48)),
                child: const Text('Aplicar filtros'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
          title: 'Buscar Paseadores', showBack: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                _search();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _showFilters,
                  icon: const Icon(Icons.tune),
                  style: IconButton.styleFrom(
                    backgroundColor: _filterType != null || _maxPrice != null
                        ? AppColors.primary
                        : AppColors.inputFill,
                    foregroundColor: _filterType != null || _maxPrice != null
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (_filterType != null || _maxPrice != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 6,
                children: [
                  if (_filterType != null)
                    Chip(
                      label: Text(_capitalize(_filterType!)),
                      onDeleted: () {
                        setState(() => _filterType = null);
                        _search();
                      },
                      backgroundColor: AppColors.primaryLight,
                    ),
                  if (_maxPrice != null)
                    Chip(
                      label: Text(
                          'Hasta \$${_maxPrice!.toStringAsFixed(0)}'),
                      onDeleted: () {
                        setState(() => _maxPrice = null);
                        _search();
                      },
                      backgroundColor: AppColors.primaryLight,
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? const EmptyState(
                        message:
                            'No se encontraron paseadores.\nIntenta cambiar los filtros.',
                        icon: Icons.search_off,
                      )
                    : RefreshIndicator(
                        onRefresh: _search,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _results.length,
                          itemBuilder: (_, i) =>
                              _WalkerResultCard(data: _results[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _WalkerResultCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _WalkerResultCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final walker = data['walkers'] as Map<String, dynamic>? ?? {};
    final name = walker['name'] as String? ?? 'Paseador';
    final photo = walker['photo_url'] as String?;
    final experience = walker['experience_years'] as int?;
    final zone = walker['coverage_zone'] as String?;
    final serviceType = data['type'] as String? ?? '';
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final priceSmall = (data['price_small'] as num?)?.toDouble();
    final priceMedium = (data['price_medium'] as num?)?.toDouble();
    final priceLarge = (data['price_large'] as num?)?.toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ServiceDetailScreen(
                serviceData: data,
                walkerData: walker,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primaryLight,
                backgroundImage: photo != null && photo.isNotEmpty
                    ? CachedNetworkImageProvider(photo)
                    : null,
                child: photo == null || photo.isEmpty
                    ? const Icon(Icons.person,
                        size: 30, color: AppColors.primary)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTextStyles.heading3),
                    Text(
                      '${_emoji(serviceType)} ${_capitalize(serviceType)} · ${_priceSummary(serviceType, price, priceSmall, priceMedium, priceLarge)}',
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.primary),
                    ),
                    if (experience != null)
                      Text('$experience años de experiencia',
                          style: AppTextStyles.bodySecondary),
                    if (zone != null)
                      Text('📍 $zone',
                          style: AppTextStyles.bodySecondary),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _priceSummary(String type, double price, double? small,
      double? medium, double? large) {
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

  String _emoji(String type) {
    switch (type) {
      case 'paseo':
        return '🦮';
      case 'cuidado':
        return '🏠';
      case 'baño':
        return '🛁';
      default:
        return '🐾';
    }
  }
}
