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
  final ServiceModel? service; // null = crear, non-null = editar

  const CreateServiceScreen({super.key, this.service});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _selectedType = AppConstants.walkerServices.first;
  String? _walkerId;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _selectedType = widget.service!.type;
      _priceCtrl.text = widget.service!.price.toStringAsFixed(0);
      _descCtrl.text = widget.service!.description ?? '';
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWalkerId());
  }

  Future<void> _loadWalkerId() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().userModel!.id;
    final data = await context
        .read<ServicesProvider>()
        ._getWalkerIdByUserId(userId);
    setState(() => _walkerId = data);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_walkerId == null) return;

    final price = double.parse(_priceCtrl.text.trim());
    final desc =
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim();
    final provider = context.read<ServicesProvider>();

    bool success;
    if (_isEditing) {
      success = await provider.updateService(
        serviceId: widget.service!.id,
        type: _selectedType,
        price: price,
        description: desc,
      );
    } else {
      success = await provider.createService(
        walkerId: _walkerId!,
        type: _selectedType,
        price: price,
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
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
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
              Wrap(
                spacing: 10,
                children: AppConstants.walkerServices.map((type) {
                  final selected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(
                        '${_emoji(type)} ${_capitalize(type)}'),
                    selected: selected,
                    selectedColor: AppColors.primaryLight,
                    onSelected: (_) =>
                        setState(() => _selectedType = type),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: selected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Precio por hora (COP)',
                  hintText: 'Ej: 25000',
                  prefixText: '\$ ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'El precio es requerido';
                  }
                  final p = double.tryParse(v.trim());
                  if (p == null || p <= 0) {
                    return 'Ingresa un precio válido mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  hintText:
                      'Describe tu servicio, experiencia, qué incluye...',
                ),
              ),
              const SizedBox(height: 32),
              CustomElevatedButton(
                label: _isEditing ? 'Guardar cambios' : 'Crear servicio',
                onPressed: _save,
                isLoading: provider.isLoading,
              ),
            ],
          ),
        ),
      ),
    );
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
}
