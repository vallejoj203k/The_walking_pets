class AppConstants {
  static const String appName = 'The Walking Pets';

  // Payments
  static const double platformCommission = 0.10; // 10%

  // Pricing (COP)
  static const double minServicePrice = 12000;     // $12.000 mínimo
  static const double additionalPetRate = 0.40;    // 40% por mascota adicional
  static const double wompiPercentage = 0.0265;    // 2.65%
  static const double wompiFixed = 700;            // $700 fijo
  static const double wompiIva = 0.19;             // IVA 19% sobre fee Wompi

  // Admin
  static const String adminEmail = 'vallejoj203k@gmail.com';

  // Roles
  static const String roleWalker = 'walker';
  static const String roleOwner = 'owner';

  // Pet types
  static const List<String> petTypes = ['perro', 'gato', 'otro'];

  // Pet sizes
  static const List<String> petSizes = ['pequeño', 'mediano', 'grande'];

  // Walker services
  static const List<String> walkerServices = ['paseo', 'cuidado', 'baño'];

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int maxNameLength = 100;

  // Storage paths
  static String walkerAvatarPath(String userId) =>
      'walkers/$userId/avatar.jpg';
  static String ownerAvatarPath(String userId) => 'owners/$userId/avatar.jpg';
}
