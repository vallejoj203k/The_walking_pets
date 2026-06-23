import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_photo_picker.dart';
import '../widgets/editable_field.dart';
import '../widgets/pet_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import '../../../config/constants/app_constants.dart';
import '../../../utils/validators.dart';

class OwnerProfileScreen extends StatefulWidget {
  final bool isEditing;

  const OwnerProfileScreen({super.key, this.isEditing = false});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
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
    await context.read<ProfileProvider>().loadOwnerProfile(userId);
    _populateFields();
  }

  void _populateFields() {
    final owner = context.read<ProfileProvider>().owner;
    if (owner != null) {
      _nameCtrl.text = owner.name;
      _addressCtrl.text = owner.address ?? '';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().userModel!.id;
    final profile = context.read<ProfileProvider>();

    final success = await profile.saveOwnerProfile(
      userId: userId,
      name: _nameCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
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
            .pushNamedAndRemoveUntil('/owner-home', (r) => false);
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

  Future<void> _showAddPetModal() async {
    final nameCtrl = TextEditingController();
    String selectedType = AppConstants.petTypes.first;
    String selectedSize = AppConstants.petSizes.first;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
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
              Text('Agregar mascota', style: AppTextStyles.heading2),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 16),
              Text('Tipo', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.petTypes.map((type) {
                  return ChoiceChip(
                    label: Text(_capitalize(type)),
                    selected: selectedType == type,
                    selectedColor: AppColors.primaryLight,
                    onSelected: (_) =>
                        setModalState(() => selectedType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text('Tamaño', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: AppConstants.petSizes.map((size) {
                  return ChoiceChip(
                    label: Text(_capitalize(size)),
                    selected: selectedSize == size,
                    selectedColor: AppColors.primaryLight,
                    onSelected: (_) =>
                        setModalState(() => selectedSize = size),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  final profile = context.read<ProfileProvider>();
                  final success = await profile.addPet(
                    name: nameCtrl.text.trim(),
                    type: selectedType,
                    size: selectedSize,
                  );
                  if (!mounted) return;
                  if (!success && profile.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(profile.error!),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text('Agregar mascota'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final email = context.read<AuthProvider>().userModel?.email ?? '';

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
                      Text('¡Hola, dueño!', style: AppTextStyles.heading2),
                      const SizedBox(height: 4),
                      Text('Cuéntanos sobre ti y tus mascotas',
                          style: AppTextStyles.bodySecondary),
                      const SizedBox(height: 24),
                    ],
                    Center(
                      child: ProfilePhotoPicker(
                        photoUrl: profile.owner?.photoUrl,
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
                      label: 'Dirección',
                      controller: _addressCtrl,
                      hint: 'Ej: Calle 80 #45-12, Bogotá',
                    ),
                    const SizedBox(height: 32),
                    CustomElevatedButton(
                      label: widget.isEditing
                          ? 'Guardar cambios'
                          : 'Crear perfil',
                      onPressed: _save,
                      isLoading: profile.isLoading,
                    ),
                    if (widget.isEditing) ...[
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Mis mascotas', style: AppTextStyles.heading2),
                          TextButton.icon(
                            onPressed: _showAddPetModal,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (profile.pets.isEmpty)
                        EmptyState(
                          message: 'Aún no tienes mascotas registradas',
                          icon: Icons.pets,
                          actionLabel: '+ Agregar mascota',
                          onAction: _showAddPetModal,
                        )
                      else
                        ...profile.pets.map((pet) => PetCard(
                              pet: pet,
                              onDelete: () => profile.deletePet(pet.id),
                            )),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
