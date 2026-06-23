import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/booking_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../../../core/models/service_model.dart';
import '../../../core/models/walker_model.dart';
import '../../../core/models/pet_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class BookingScreen extends StatefulWidget {
  final ServiceModel service;
  final WalkerModel walker;

  const BookingScreen(
      {super.key, required this.service, required this.walker});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _notesCtrl = TextEditingController();
  DateTime? _scheduledDate;
  String? _selectedPetId;
  String? _ownerId;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOwner());
  }

  Future<void> _loadOwner() async {
    if (!mounted) return;
    final userId = context.read<AuthProvider>().userModel!.id;
    await context.read<ProfileProvider>().loadOwnerProfile(userId);
    if (mounted) {
      setState(() => _ownerId = context.read<ProfileProvider>().owner?.id);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('es'),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    setState(() {
      _scheduledDate = DateTime(
          date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _confirm() async {
    if (_scheduledDate == null) {
      _showError('Selecciona una fecha y hora');
      return;
    }
    if (_scheduledDate!.isBefore(DateTime.now())) {
      _showError('La fecha no puede ser en el pasado');
      return;
    }
    if (_selectedPetId == null) {
      _showError('Selecciona una mascota');
      return;
    }
    if (_ownerId == null) {
      _showError('No se encontró tu perfil de dueño');
      return;
    }

    setState(() => _loading = true);
    final success = await context.read<BookingProvider>().createBooking(
          walkerId: widget.walker.id,
          ownerId: _ownerId!,
          serviceId: widget.service.id,
          petId: _selectedPetId!,
          scheduledDate: _scheduledDate!,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Reserva creada! El paseador recibirá tu solicitud.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      _showError(context.read<BookingProvider>().error ?? 'Error al crear reserva');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>();
    final pets = profile.pets;
    final fmt = DateFormat('dd/MM/yyyy HH:mm', 'es');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Confirmar reserva'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Resumen', style: AppTextStyles.heading3),
                    const SizedBox(height: 12),
                    _Row('Paseador', widget.walker.name),
                    _Row('Servicio',
                        '${widget.service.typeEmoji} ${widget.service.typeLabel}'),
                    _Row('Precio', _priceDisplay(profile.pets)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Fecha y hora
            Text('Fecha y hora', style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _scheduledDate != null
                          ? fmt.format(_scheduledDate!)
                          : 'Seleccionar fecha y hora',
                      style: AppTextStyles.body.copyWith(
                        color: _scheduledDate != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Mascota
            Text('Mascota', style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            if (pets.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                    'No tienes mascotas registradas. Agrega una desde tu perfil.',
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ...pets.map((pet) => RadioListTile<String>(
                    value: pet.id,
                    groupValue: _selectedPetId,
                    onChanged: (v) => setState(() => _selectedPetId = v),
                    title: Text('${pet.typeEmoji} ${pet.name}'),
                    subtitle: Text(
                        '${_capitalize(pet.type)} · ${_capitalize(pet.size)}'),
                    activeColor: AppColors.primary,
                  )),
            const SizedBox(height: 20),

            // Notas
            Text('Notas (opcional)', style: AppTextStyles.heading3),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText:
                    'Instrucciones especiales, alergias, rutinas...',
              ),
            ),
            const SizedBox(height: 32),
            CustomElevatedButton(
              label: 'Confirmar reserva',
              onPressed: _confirm,
              isLoading: _loading,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _priceDisplay(List<PetModel> pets) {
    if (widget.service.type == 'baño' && _selectedPetId != null) {
      final idx = pets.indexWhere((p) => p.id == _selectedPetId);
      if (idx != -1) {
        final p = widget.service.priceForSize(pets[idx].size);
        if (p != null) {
          return '\$${p.toStringAsFixed(0)} COP (${_capitalize(pets[idx].size)})';
        }
      }
    }
    return widget.service.priceSummary;
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
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
