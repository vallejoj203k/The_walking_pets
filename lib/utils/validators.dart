import '../core/extensions/string_extensions.dart';

class Validators {
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'El email es requerido';
    if (!value.isValidEmail) return 'Ingresa un email válido';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es requerida';
    if (value.length < 8) return 'Mínimo 8 caracteres';
    if (value.length > 50) return 'Máximo 50 caracteres';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirma tu contraseña';
    if (value != password) return 'Las contraseñas no coinciden';
    return null;
  }

  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName es requerido';
    if (value.trim().length > 100) return '$fieldName es muy largo';
    return null;
  }

  static String? hourlyRate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) return 'Ingresa una tarifa válida';
    return null;
  }

  static String? experienceYears(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0 || parsed > 50) {
      return 'Ingresa años válidos (0-50)';
    }
    return null;
  }
}
