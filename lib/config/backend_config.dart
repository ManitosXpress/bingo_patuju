class BackendConfig {
  // Configuración del backend - Firebase Functions
  // Para desarrollo local, usa el emulador de Firebase Functions
  // Para producción, usa la URL real de Firebase Functions
  static const bool useLocalEmulator = false; // ✅ PRODUCCIÓN: Firebase Functions en la nube
  
  static String get baseUrl {
    if (useLocalEmulator) {
      return 'http://localhost:5001/bingo-baitty/us-central1/api';
    }
    return 'https://api-qijtzxgljq-uc.a.run.app';
  }
  
  // Endpoints de la API
  static const String cardsEndpoint = '/cards';
  static const String vendorsEndpoint = '/vendors';
  static const String salesEndpoint = '/sales';
  static const String reportsEndpoint = '/reports';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Configuración de reintentos
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
  
  // URLs completas
  static String get cardsUrl => '$baseUrl$cardsEndpoint';
  static String get vendorsUrl => '$baseUrl$vendorsEndpoint';
  static String get salesUrl => '$baseUrl$salesEndpoint';
  static String get reportsUrl => '$baseUrl$reportsEndpoint';
  
  // URL base para compatibilidad con GameStateProvider
  static String get apiBase => baseUrl;
  
  // Verificar si estamos en modo desarrollo
  static bool get isDevelopment => useLocalEmulator || baseUrl.contains('localhost') || baseUrl.contains('127.0.0.1');
  
  // Configuración para diferentes entornos
  static String get environment {
    if (isDevelopment) return 'development';
    if (baseUrl.contains('staging')) return 'staging';
    return 'production';
  }
} 