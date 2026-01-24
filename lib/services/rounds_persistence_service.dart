import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/backend_config.dart';

class RoundsPersistenceService {
  static final RoundsPersistenceService _instance = RoundsPersistenceService._internal();
  
  factory RoundsPersistenceService() {
    return _instance;
  }
  
  RoundsPersistenceService._internal();
  
  static const String _selectedRoundsKey = 'selected_rounds_map';
  static const String _completedGamesKey = 'completed_games_list';

  /// Guarda la ronda seleccionada para un juego específico
  Future<void> saveSelectedRound(String gameId, String roundId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Obtener mapa actual o crear uno nuevo
      // El formato será "gameId:roundId" en una lista de strings para simular un mapa
      // O mejor, usamos un prefijo para cada key: "selected_round_gameId"
      
      await prefs.setString('selected_round_$gameId', roundId);
      print('DEBUG: Ronda $roundId guardada para el juego $gameId');
    } catch (e) {
      print('ERROR: Error guardando ronda seleccionada: $e');
    }
  }

  /// Obtiene la ronda seleccionada para un juego
  Future<String?> getSelectedRound(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('selected_round_$gameId');
    } catch (e) {
      print('ERROR: Error obteniendo ronda seleccionada: $e');
      return null;
    }
  }

  /// Guarda la lista de juegos completados (tachados)
  Future<void> saveCompletedGames(List<String> gameIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_completedGamesKey, gameIds);
      print('DEBUG: Juegos completados guardados: $gameIds');
    } catch (e) {
      print('ERROR: Error guardando juegos completados: $e');
    }
  }

  /// Obtiene la lista de juegos completados
  Future<List<String>> getCompletedGames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_completedGamesKey) ?? [];
    } catch (e) {
      print('ERROR: Error obteniendo juegos completados: $e');
      return [];
    }
  }

  // Obtener rondas completadas de un juego
  Future<List<String>> getCompletedRounds(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('completed_rounds_$gameId') ?? [];
    } catch (e) {
      print('ERROR: Error obteniendo rondas completadas: $e');
      return [];
    }
  }

  // Guardar rondas completadas de un juego
  Future<void> saveCompletedRounds(String gameId, List<String> completedRounds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('completed_rounds_$gameId', completedRounds);
      print('DEBUG: Rondas completadas guardadas para $gameId: $completedRounds');
    } catch (e) {
      print('ERROR: Error guardando rondas completadas: $e');
    }
  }

  /// Guarda el mapa de patrones marcados manualmente para un juego específico
  static Future<void> saveMarkedPatterns(String gameId, String gameDate, Map<String, bool> patterns) async {
    try {
      // Usar la fecha del juego como eventId
      final date = gameDate;
      
      final url = '${BackendConfig.apiBase}/bingo/$date/games/$gameId/patterns';
      print('DEBUG: Guardando patrones marcados en: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: BackendConfig.defaultHeaders,
        body: json.encode({'patterns': patterns}),
      ).timeout(BackendConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        print('DEBUG: ${patterns.length} patrones guardados exitosamente para $gameId');
        print('DEBUG: Respuesta del servidor: ${response.body}');
      } else {
        print('ERROR: Error guardando patrones: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('ERROR: Error guardando patrones marcados: $e');
    }
  }

  /// Carga el mapa de patrones marcados manualmente para un juego específico
  static Future<Map<String, bool>> loadMarkedPatterns(String gameId, String gameDate) async {
    try {
      // Usar la fecha del juego como eventId
      final date = gameDate;
      
      final url = '${BackendConfig.apiBase}/bingo/$date/games/$gameId/patterns';
      print('DEBUG: Cargando patrones marcados desde: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: BackendConfig.defaultHeaders,
      ).timeout(BackendConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final patternsData = data['data'] as Map<String, dynamic>;
        
        // Convertir a Map<String, bool>
        final Map<String, bool> patterns = {};
        patternsData.forEach((key, value) {
          patterns[key] = value == true;
        });
        
        print('DEBUG: ${patterns.length} patrones marcados cargados para $gameId');
        return patterns;
      } else if (response.statusCode == 404) {
        print('DEBUG: No hay patrones marcados guardados para $gameId');
        return {};
      } else {
        print('ERROR: Error cargando patrones: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      print('ERROR: Error cargando patrones marcados: $e');
      return {};
    }
  }

  /// Limpia los patrones marcados manualmente para un juego específico
  static Future<void> clearMarkedPatterns(String gameId, String gameDate) async {
    try {
      final date = gameDate;
      
      final url = '${BackendConfig.apiBase}/bingo/$date/games/$gameId/patterns';
      print('DEBUG: Limpiando patrones marcados en: $url');
      
      final response = await http.delete(
        Uri.parse(url),
        headers: BackendConfig.defaultHeaders,
      ).timeout(BackendConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        print('DEBUG: Patrones marcados eliminados para $gameId');
      } else {
        print('ERROR: Error eliminando patrones: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Error eliminando patrones marcados: $e');
    }
  }
}
