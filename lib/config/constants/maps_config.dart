class MapsConfig {
  // Reemplaza con tu API Key de Google Cloud Console
  // Habilita: Maps SDK for Android, Maps SDK for iOS
  static const String apiKey = 'TU_GOOGLE_MAPS_API_KEY_AQUI';

  // Radio máximo de búsqueda en km
  static const double maxSearchRadiusKm = 50.0;

  // Intervalo de actualización de ubicación en segundos
  static const int locationUpdateIntervalSeconds = 10;

  // Coordenadas por defecto (Bogotá, Colombia)
  static const double defaultLat = 4.7110;
  static const double defaultLng = -74.0721;
}
