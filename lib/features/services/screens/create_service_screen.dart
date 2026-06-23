import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/services_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/models/service_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants/app_constants.dart';

class CreateServiceScreen extends StatefulWidget {
  final ServiceModel? service;

  const CreateServiceScreen({super.key, this.service});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  // Paseo / Cuidado
  final _priceCtrl = TextEditingController();

  // Baño por tamaño
  final _priceSmallCtrl = TextEditingController();
  final _priceMediumCtrl = TextEditingController();
  final _priceLargeCtrl = TextEditingController();

  final _descCtrl = TextEditingController();
  String _selectedType = AppConstants.walkerServices.first;
  String? _walkerId;

  bool get _isEditing => widget.service != null;
  bool get _isBath => _selectedType == 'baño';
  bool get _isCare => _selectedType == 'cuidado';

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _selectedType = widget.service!.type;
      _priceCtrl.text = widget.service!.price > 0
          ? widget.service!.price.toStringAsFixed(0)
          : '';
      _priceSmallCtrl.text =
          widget.service!.priceSmall?.toStringAsFixed(0) ?? '';
      _priceMediumCtrl.text =
          widget.service!.priceMedium?.toStringAsFixed(0) ?? '';
      _priceLargeCtrl.text =
          widget.service!.priceLarge?.toStringAsFixed(0) ?? '';
      _descCtrl.text = widget.service!.description ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWalkerId());
  }

  Future<void> _loadWalkerId() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().userModel!.id;
    final id = await context
        .read<ServicesProvider>()
        .getWalkerIdByUserId(userId);
    setState(() => _walkerId = id);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_walkerId == null) return;

    final provider = context.read<ServicesProvider>();

    double price = 0;
    double? priceSmall, priceMedium, priceLarge;

    if (_isBath) {
      priceSmall = double.tryParse(_priceSmallCtrl.text.trim());
      priceMedium = double.tryParse(_priceMediumCtrl.text.trim());
      priceLarge = double.tryParse(_priceLargeCtrl.text.trim());
    } else {
      price = double.parse(_priceCtrl.text.trim());
    }

    final desc = _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();

    bool success;
    if (_isEditing) {
      success = await provider.updateService(
        serviceId: widget.service!.id,
        type: _selectedType,
        price: price,
        priceSmall: priceSmall,
        priceMedium: priceMedium,
        priceLarge: priceLarge,
        description: desc,
      );
    } else {
      success = await provider.createService(
        walkerId: _walkerId!,
        type: _selectedType,
        price: price,
        priceSmall: priceSmall,
        priceMedium: priceMedium,
        priceLarge: priceLarge,
        description: desc,
      );
    }

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Servicio actualizado'
              : 'Servicio creado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(provider.error!),
            backgroundColor: AppColors.error),
      );
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _priceSmallCtrl.dispose();
    _priceMediumCtrl.dispose();
    _priceLargeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ServicesProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: _isEditing ? 'Editar servicio' : 'Nuevo servicio',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tipo de servicio', style: AppTextStyles.heading3),
              const SizedBox(height: 12),
              // Selector de tipo
              ...AppConstants.walkerServices.map((type) {
                final selected = _selectedType == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primaryLight
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.inputBorder,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(_emoji(type),
                            style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_capitalize(type),
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  )),
                              Text(
                                _priceHint(type),
                                style: AppTextStyles.caption,
                              ),
                            ],
                          ),
                        ),
                        if (selected)
                          const Icon(Icons.check_circle,
                              color: AppColors.primary),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 24),
              Text('Precio', style: AppTextStyles.heading3),
              const SizedBox(height: 12),

              // Campos de precio según tipo
              if (!_isBath) ...[
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: _isCare
                        ? 'Precio por día (COP)'
                        : 'Precio por hora (COP)',
                    hintText: _isCare ? 'Ej: 80000' : 'Ej: 25000',
                    prefixText: '\$ ',
                    suffixText: _isCare ? '/día' : '/hora',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El precio es requerido';
                    }
                    final p = double.tryParse(v.trim());
                    if (p == null || p <= 0) {
                      return 'Ingresa un precio válido';
                    }
                    return null;
                  },
                ),
              ] else ...[
                // Baño: tres precios por tamaño
                _BathPriceField(
                  label: '🐕 Perro pequeño',
                  hint: 'Ej: 30000',
                  controller: _priceSmallCtrl,
                ),
                const SizedBox(height: 12),
                _BathPriceField(
                  label: '🐕 Perro mediano',
                  hint: 'Ej: 45000',
                  controller: _priceMediumCtrl,
                ),
                const SizedBox(height: 12),
                _BathPriceField(
                  label: '🐕 Perro grande',
                  hint: 'Ej: 60000',
                  controller: _priceLargeCtrl,
                ),
                // Validar que al menos uno tenga precio
                Builder(builder: (ctx) {
                  return const SizedBox.shrink();
                }),
              ],

              const SizedBox(height: 20),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText: 'Describe qué incluye tu servicio...',
                ),
              ),
              const SizedBox(height: 32),
              CustomElevatedButton(
                label: _isEditing ? 'Guardar cambios' : 'Crear servicio',
                onPressed: _validateAndSave,
                isLoading: provider.isLoading,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _validateAndSave() async {
    if (_isBath) {
      final s = double.tryParse(_priceSmallCtrl.text.trim());
      final m = double.tryParse(_priceMediumCtrl.text.trim());
      final l = double.tryParse(_priceLargeCtrl.text.trim());
      if (s == null && m == null && l == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ingresa el precio para al menos un tamaño'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    }
    _save();
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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

  String _priceHint(String type) {
    switch (type) {
      case 'paseo':
        return 'Se cobra por hora';
      case 'cuidado':
        return 'Se cobra por día';
      case 'baño':
        return 'Se cobra según el tamaño del perro';
      default:
        return '';
    }
  }
}

class _BathPriceField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  const _BathPriceField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixText: '\$ ',
        suffixText: 'COP',
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null; // opcional
        final p = double.tryParse(v.trim());
        if (p == null || p <= 0) return 'Precio inválido';
        return null;
      },
    );
  }
}
