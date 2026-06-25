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
import '../../../config/constants/app_constants.dart';

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
  final Set<String> _selectedPetIds = {};
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

  double _basePrice(List<PetModel> pets) {
    if (widget.service.type == 'baño' && _selectedPetIds.isNotEmpty) {
      final pet = pets.firstWhere((p) => p.id == _selectedPetIds.first,
          orElse: () => pets.first);
      return widget.service.priceForSize(pet.size) ?? widget.service.price;
    }
    return widget.service.price;
  }

  double _totalPrice(List<PetModel> pets) {
    final base = _basePrice(pets);
    final additional = _selectedPetIds.length > 1
        ? (_selectedPetIds.length - 1) * base * AppConstants.additionalPetRate
        : 0.0;
    return base + additional;
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
    if (_selectedPetIds.isEmpty) {
      _showError('Selecciona al menos una mascota');
      return;
    }
    if (_ownerId == null) {
      _showError('No se encontró tu perfil de dueño');
      return;
    }

    final pets = context.read<ProfileProvider>().pets;
    final total = _totalPrice(pets);

    setState(() => _loading = true);
    final success = await context.read<BookingProvider>().createBooking(
          walkerId: widget.walker.id,
          ownerId: _ownerId!,
          serviceId: widget.service.id,
          petId: _selectedPetIds.first,
          petIds: _selectedPetIds.toList(),
          totalAmount: total,
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
    final base = _selectedPetIds.isNotEmpty ? _basePrice(pets) : widget.service.price;
    final total = _selectedPetIds.isNotEmpty ? _totalPrice(pets) : null;
    final additionalCount = _selectedPetIds.length > 1 ? _selectedPetIds.length - 1 : 0;
    final numFmt = NumberFormat('#,###', 'es_CO');

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
                    _Row('Precio base', '\$${numFmt.format(base)} COP'),
                    if (additionalCount > 0) ...[
                      _Row(
                        'Mascotas adicionales',
                        '$additionalCount × 40% = \$${numFmt.format(additionalCount * base * AppConstants.additionalPetRate)} COP',
                      ),
                      const Divider(height: 16),
                      _Row(
                        'Total servicio',
                        '\$${numFmt.format(total!)} COP',
                        bold: true,
                      ),
                    ],
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

            // Mascotas (multi-select)
            Text('Mascotas', style: AppTextStyles.heading3),
            const SizedBox(height: 4),
            Text(
              'Puedes seleccionar varias mascotas. Cada mascota adicional cuesta 40% del precio base.',
              style: AppTextStyles.caption,
            ),
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
              ...pets.map((pet) {
                final selected = _selectedPetIds.contains(pet.id);
                return CheckboxListTile(
                  value: selected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedPetIds.add(pet.id);
                      } else {
                        _selectedPetIds.remove(pet.id);
                      }
                    });
                  },
                  title: Text('${pet.typeEmoji} ${pet.name}'),
                  subtitle: Text(
                      '${_capitalize(pet.type)} · ${_capitalize(pet.size)}'),
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }),
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

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _Row(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: AppTextStyles.bodySecondary),
          ),
          Expanded(
            child: Text(
              value,
              style: bold
                  ? AppTextStyles.body.copyWith(fontWeight: FontWeight.w700)
                  : AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}
