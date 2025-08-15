import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/backend_config.dart';

class CartillaService {
  // Obtener todas las cartillas con paginación
  static Future<List<Map<String, dynamic>>> getCartillas({
    String? assignedTo,
    bool? sold,
    int page = 0,
    int limit = 10,
  }) async {
    return _makeRequestWithRetry(() async {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (assignedTo != null) queryParams['assignedTo'] = assignedTo;
      if (sold != null) queryParams['sold'] = sold.toString();
      
      final uri = Uri.parse(BackendConfig.cardsUrl).replace(queryParameters: queryParams);
      
      print('DEBUG: Solicitando cartillas: $uri');
      
      final response = await http.get(
        uri,
        headers: BackendConfig.defaultHeaders,
      ).timeout(BackendConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Error al obtener cartillas: ${response.statusCode} - ${response.body}');
      }
    });
  }
  
  // Crear una nueva cartilla
  static Future<Map<String, dynamic>> createCartilla(List<List<int>> numbers, {int? cardNo}) async {
    return _makeRequestWithRetry(() async {
      final response = await http.post(
        Uri.parse(BackendConfig.cardsUrl),
        headers: BackendConfig.defaultHeaders,
        body: json.encode({
          'numbers': numbers,
          if (cardNo != null) 'cardNo': cardNo,
        }),
      ).timeout(BackendConfig.connectionTimeout);
      
      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al crear cartilla: ${response.statusCode} - ${response.body}');
      }
    });
  }
  
  // Asignar cartilla a un vendedor
  static Future<Map<String, dynamic>> assignCartilla(String cartillaId, String vendorId) async {
    return _makeRequestWithRetry(() async {
      final response = await http.post(
        Uri.parse('${BackendConfig.cardsUrl}/$cartillaId/assign'),
        headers: BackendConfig.defaultHeaders,
        body: json.encode({'vendorId': vendorId}),
      ).timeout(BackendConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al asignar cartilla: ${response.statusCode} - ${response.body}');
      }
    });
  }
  
  // Desasignar cartilla
  static Future<Map<String, dynamic>> unassignCartilla(String cartillaId) async {
    return _makeRequestWithRetry(() async {
      final response = await http.post(
        Uri.parse('${BackendConfig.cardsUrl}/$cartillaId/unassign'),
        headers: BackendConfig.defaultHeaders,
      ).timeout(BackendConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al desasignar cartilla: ${response.statusCode} - ${response.body}');
      }
    });
  }
  
  // Eliminar cartilla
  static Future<bool> deleteCartilla(String id) async {
    try {
      final response = await _makeRequestWithRetry(
        () => http.delete(
          Uri.parse('${BackendConfig.apiBase}/cards/$id'),
          headers: BackendConfig.defaultHeaders,
        ),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error eliminando cartilla: $e');
      return false;
    }
  }

  // Generar cartillas automáticamente
  static Future<Map<String, dynamic>?> generateCartillas(int count) async {
    try {
      final response = await _makeRequestWithRetry(
        () => http.post(
          Uri.parse('${BackendConfig.apiBase}/cards/generate'),
          headers: BackendConfig.defaultHeaders,
          body: json.encode({'count': count}),
        ),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        print('DEBUG: Se generaron $count cartillas exitosamente');
        return responseData;
      } else {
        print('Error generando cartillas: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error generando cartillas: $e');
      return null;
    }
  }

  // Eliminar TODAS las cartillas
  static Future<Map<String, dynamic>?> clearAllCartillas() async {
    try {
      final response = await _makeRequestWithRetry(
        () => http.delete(
          Uri.parse('${BackendConfig.apiBase}/cards/clear'),
          headers: BackendConfig.defaultHeaders,
        ),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        print('Error eliminando todas las cartillas: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error eliminando todas las cartillas: $e');
      return null;
    }
  }
  
  // Marcar cartilla como vendida
  static Future<Map<String, dynamic>> markCartillaAsSold(String cartillaId) async {
    return _makeRequestWithRetry(() async {
      final response = await http.post(
        Uri.parse('${BackendConfig.cardsUrl}/$cartillaId/sold'),
        headers: BackendConfig.defaultHeaders,
        body: json.encode({'sold': true}),
      ).timeout(BackendConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Error al marcar cartilla como vendida: ${response.statusCode} - ${response.body}');
      }
    });
  }
  
  // Generar cartillas automáticamente (5x5)
  static List<List<int>> generateBingoCard() {
    final List<List<int>> card = [];
    
    // Columna B: 1-15
    final colB = _generateRandomNumbers(1, 15, 5);
    // Columna I: 16-30
    final colI = _generateRandomNumbers(16, 30, 5);
    // Columna N: 31-45
    final colN = _generateRandomNumbers(31, 45, 5);
    // Columna G: 46-60
    final colG = _generateRandomNumbers(46, 60, 5);
    // Columna O: 61-75
    final colO = _generateRandomNumbers(61, 75, 5);
    
    // Crear filas
    for (int i = 0; i < 5; i++) {
      card.add([colB[i], colI[i], colN[i], colG[i], colO[i]]);
    }
    
    return card;
  }
  
  // Generar múltiples cartillas
  static List<List<List<int>>> generateMultipleBingoCards(int count) {
    final List<List<List<int>>> cards = [];
    for (int i = 0; i < count; i++) {
      cards.add(generateBingoCard());
    }
    return cards;
  }
  
  // Crear múltiples cartillas en Firebase
  static Future<List<Map<String, dynamic>>> createMultipleCartillas(int count) async {
    final List<Map<String, dynamic>> createdCards = [];
    
    for (int i = 0; i < count; i++) {
      try {
        final numbers = generateBingoCard();
        final cardData = await createCartilla(numbers);
        createdCards.add(cardData);
        
        // Pequeña pausa entre creaciones para no sobrecargar el servidor
        if (i < count - 1) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        print('Error creando cartilla ${i + 1}: $e');
        // Continuar con las siguientes cartillas
      }
    }
    
    return createdCards;
  }
  
  static List<int> _generateRandomNumbers(int min, int max, int count) {
    final List<int> numbers = [];
    final List<int> range = List.generate(max - min + 1, (i) => min + i);
    range.shuffle();
    
    for (int i = 0; i < count; i++) {
      numbers.add(range[i]);
    }
    
    return numbers;
  }
  
  // Función helper para reintentos
  static Future<T> _makeRequestWithRetry<T>(Future<T> Function() request) async {
    int attempts = 0;
    
    while (attempts < BackendConfig.maxRetries) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        
        if (attempts >= BackendConfig.maxRetries) {
          throw Exception('Error después de ${BackendConfig.maxRetries} intentos: $e');
        }
        
        // Esperar antes del siguiente intento
        await Future.delayed(BackendConfig.retryDelay * attempts);
        
        print('Reintentando solicitud (intento $attempts)...');
      }
    }
    
    throw Exception('Error inesperado en la solicitud');
  }
  
  // Verificar conectividad con el backend
  static Future<bool> checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${BackendConfig.baseUrl}/health'),
        headers: BackendConfig.defaultHeaders,
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error verificando salud del backend: $e');
      return false;
    }
  }
} 