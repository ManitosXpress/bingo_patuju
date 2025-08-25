import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bingo_game_config.dart';

class RoundsPersistenceService {
  static const String _roundsKey = 'bingo_game_rounds';
  static const String _currentGameKey = 'current_bingo_game';
  static const String _currentRoundIndexKey = 'current_round_index';

  /// Guardar las rondas de un juego específico
  static Future<void> saveGameRounds(BingoGameConfig game) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Guardar el juego completo
      final gameData = game.toJson();
      await prefs.setString(_roundsKey, jsonEncode(gameData));
      
      // Guardar el ID del juego actual
      await prefs.setString(_currentGameKey, game.id);
      
      print('DEBUG: Rondas guardadas para el juego: ${game.name}');
    } catch (e) {
      print('ERROR: Error guardando rondas: $e');
    }
  }

  /// Cargar las rondas guardadas para un juego específico
  static Future<BingoGameConfig?> loadGameRounds(String gameId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roundsData = prefs.getString(_roundsKey);
      
      if (roundsData != null) {
        final gameData = jsonDecode(roundsData) as Map<String, dynamic>;
        final savedGameId = gameData['id'] as String?;
        
        // Solo cargar si es el mismo juego
        if (savedGameId == gameId) {
          final game = BingoGameConfig.fromJson(gameData);
          print('DEBUG: Rondas cargadas para el juego: ${game.name}');
          return game;
        }
      }
      
      return null;
    } catch (e) {
      print('ERROR: Error cargando rondas: $e');
      return null;
    }
  }

  /// Guardar el índice de la ronda actual
  static Future<void> saveCurrentRoundIndex(int roundIndex) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_currentRoundIndexKey, roundIndex);
      print('DEBUG: Índice de ronda actual guardado: $roundIndex');
    } catch (e) {
      print('ERROR: Error guardando índice de ronda: $e');
    }
  }

  /// Cargar el índice de la ronda actual
  static Future<int> loadCurrentRoundIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_currentRoundIndexKey) ?? 0;
    } catch (e) {
      print('ERROR: Error cargando índice de ronda: $e');
      return 0;
    }
  }

  /// Obtener el ID del juego actual
  static Future<String?> getCurrentGameId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_currentGameKey);
    } catch (e) {
      print('ERROR: Error obteniendo ID del juego actual: $e');
      return null;
    }
  }

  /// Limpiar todos los datos guardados
  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_roundsKey);
      await prefs.remove(_currentGameKey);
      await prefs.remove(_currentRoundIndexKey);
      print('DEBUG: Todos los datos de persistencia han sido limpiados');
    } catch (e) {
      print('ERROR: Error limpiando datos: $e');
    }
  }

  /// Verificar si hay datos guardados
  static Future<bool> hasSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_roundsKey);
    } catch (e) {
      print('ERROR: Error verificando datos guardados: $e');
      return false;
    }
  }
}
