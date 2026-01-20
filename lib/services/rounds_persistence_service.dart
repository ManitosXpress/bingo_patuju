import 'package:shared_preferences/shared_preferences.dart';

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
}
