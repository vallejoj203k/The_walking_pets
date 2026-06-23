import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_photo_picker.dart';
import '../widgets/editable_field.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants/app_constants.dart';
import '../../../utils/validators.dart';

class WalkerProfileScreen extends StatefulWidget {
  final bool isEditing;

  const WalkerProfileScreen({super.key, this.isEditing = false});

  @override
  State<WalkerProfileScreen> createState() => _WalkerProfileScreenState();
}

class _WalkerProfileScreenState extends State<WalkerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _zoneCtrl = TextEditingController();
  List<String> _selectedServices = [];
  File? _photoFile;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    final userId = context.read<AuthProvider>().userModel!.id;
    await context.read<ProfileProvider>().loadWalkerProfile(userId);
    _populateFields();
  }

  void _populateFields() {
    final walker = context.read<ProfileProvider>().walker;
    if (walker != null) {
      _nameCtrl.text = walker.name;
      _experienceCtrl.text = walker.experienceYears?.toString() ?? '';
      _rateCtrl.text = walker.hourlyRate?.toString() ?? '';
      _zoneCtrl.text = walker.coverageZone ?? '';
      setState(() => _selectedServices = List.from(walker.services));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_nameCtrl.text.trim().isEmpty) return;

    final userId = context.read<AuthProvider>().userModel!.id;
    final profile = context.read<ProfileProvider>();

    final success = await profile.saveWalkerProfile(
      userId: userId,
      name: _nameCtrl.text.trim(),
      services: _selectedServices,
      experienceYears: _experienceCtrl.text.trim().isEmpty
          ? null
          : int.tryParse(_experienceCtrl.text.trim()),
      hourlyRate: _rateCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_rateCtrl.text.trim()),
      coverageZone: _zoneCtrl.text.trim().isEmpty ? null : _zoneCtrl.text.trim(),
      photoFile: _photoFile,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil guardado exitosamente'),
          backgroundColor: AppColors.success,
        ),
      );
      if (!widget.isEditing) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/walker-home', (r) => false);
      }
    } else if (profile.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profile.error!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickPhoto() async {
    final file = await ProfilePhotoPicker.pickImage();
    if (file != null) setState(() => _photoFile = file);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _experienceCtrl.dispose();
    _rateCtrl.dispose();
    _zoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final email =
        context.read<AuthProvider>().userModel?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: widget.isEditing ? 'Editar perfil' : 'Completa tu perfil',
        showBack: widget.isEditing,
      ),
      body: profile.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.isEditing) ...[
                      Text('¡Hola, paseador!', style: AppTextStyles.heading2),
                      const SizedBox(height: 4),
                      Text('Cuéntanos más sobre ti',
                          style: AppTextStyles.bodySecondary),
                      const SizedBox(height: 24),
                    ],
                    Center(
                      child: ProfilePhotoPicker(
                        photoUrl: profile.walker?.photoUrl,
                        localFile: _photoFile,
                        onTap: _pickPhoto,
                      ),
                    ),
                    const SizedBox(height: 24),
                    EditableField(
                      label: 'Nombre completo',
                      controller: _nameCtrl,
                      validator: (v) =>
                          Validators.requiredField(v, 'El nombre'),
                    ),
                    const SizedBox(height: 16),
                    EditableField(
                      label: 'Email',
                      controller: TextEditingController(text: email),
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),
                    EditableField(
                      label: 'Años de experiencia',
                      controller: _experienceCtrl,
                      keyboardType: TextInputType.number,
                      validator: Validators.experienceYears,
                      hint: 'Ej: 3',
                    ),
                    const SizedBox(height: 16),
                    EditableField(
                      label: 'Tarifa por hora (COP)',
                      controller: _rateCtrl,
                      keyboardType: TextInputType.number,
                      validator: Validators.hourlyRate,
                      hint: 'Ej: 25000',
                    ),
                    const SizedBox(height: 16),
                    EditableField(
                      label: 'Zona de cobertura',
                      controller: _zoneCtrl,
                      hint: 'Ej: Chapinero, Usaquén',
                    ),
                    const SizedBox(height: 20),
                    Text('Servicios que ofreces',
                        style: AppTextStyles.heading3),
                    const SizedBox(height: 12),
                    _buildServicesSection(),
                    const SizedBox(height: 32),
                    CustomElevatedButton(
                      label: widget.isEditing
                          ? 'Guardar cambios'
                          : 'Crear perfil',
                      onPressed: _save,
                      isLoading: profile.isLoading,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildServicesSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.walkerServices.map((service) {
        final selected = _selectedServices.contains(service);
        return FilterChip(
          label: Text(_capitalizeService(service)),
          selected: selected,
          onSelected: (val) {
            setState(() {
              if (val) {
                _selectedServices.add(service);
              } else {
                _selectedServices.remove(service);
              }
            });
          },
          selectedColor: AppColors.primaryLight,
          checkmarkColor: AppColors.primary,
          labelStyle: TextStyle(
            color: selected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  String _capitalizeService(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
