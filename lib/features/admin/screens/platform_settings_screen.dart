import 'package:flutter/material.dart';
import '../providers/admin_provider.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class PlatformSettingsScreen extends StatefulWidget {
  final AdminProvider adminProvider;
  const PlatformSettingsScreen({super.key, required this.adminProvider});

  @override
  State<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends State<PlatformSettingsScreen> {
  Map<String, dynamic> _settings = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await widget.adminProvider.getPlatformSettings();
    if (mounted) {
      setState(() {
        _settings = s;
        for (final key in s.keys) {
          _controllers[key] = TextEditingController(
              text: (s[key] as Map?)?['value'] as String? ?? '');
        }
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    bool allOk = true;
    for (final entry in _controllers.entries) {
      final ok = await widget.adminProvider
          .updatePlatformSetting(entry.key, entry.value.text.trim());
      if (!ok) allOk = false;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(allOk
              ? 'Configuración guardada.'
              : 'Algunos ajustes no se guardaron.'),
          backgroundColor: allOk ? AppColors.success : AppColors.error,
        ),
      );
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_settings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.settings_suggest,
                size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            const Text(
                'No hay configuración disponible.\n'
                'Crea la tabla platform_settings en Supabase.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final descriptions = <String, String>{
      'commission_rate': 'Comisión de la plataforma (%)',
      'min_service_price': 'Precio mínimo de servicio (COP)',
      'max_service_price': 'Precio máximo de servicio (COP)',
      'max_search_distance': 'Distancia máxima de búsqueda (km)',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Parámetros de plataforma',
                    style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text('Los cambios aplican inmediatamente.',
                    style: AppTextStyles.bodySecondary),
                const Divider(height: 24),
                ..._controllers.entries.map((entry) {
                  final desc =
                      ((_settings[entry.key] as Map?)?['description'] as String?) ??
                          descriptions[entry.key] ??
                          entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(desc, style: AppTextStyles.label),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: entry.value,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            isDense: true,
                            suffixText: entry.key == 'commission_rate'
                                ? '%'
                                : entry.key == 'max_search_distance'
                                    ? 'km'
                                    : 'COP',
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48)),
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child:
                      CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Guardar configuración'),
        ),
      ],
    );
  }
}
