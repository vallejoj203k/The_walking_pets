extension StringValidations on String {
  bool get isValidEmail {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(trim());
  }

  bool get isValidPassword {
    final trimmed = trim();
    return trimmed.length >= 8 && trimmed.length <= 50;
  }

  bool get isNotBlank => trim().isNotEmpty;
}
