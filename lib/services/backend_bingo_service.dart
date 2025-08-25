import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/firebase_bingo_game.dart';

/// Servicio para manejar los juegos de bingo a través del backend Express
class BackendBingoService {
  static const String _baseUrl = 'http://localhost:4001/api/bingo';
  
  /// Obtener todos los juegos de bingo
  Future<List<FirebaseBingoGame>> getAllBingoGames() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          final List<dynamic> gamesData = responseData['data'];
          return gamesData.map((gameData) => FirebaseBingoGame.fromMap(gameData)).toList();
        } else {
          throw Exception('Error del servidor: ${responseData['error']}');
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Error obteniendo juegos de bingo: $e');
      rethrow;
    }
  }

  /// Obtener un juego específico por ID
  Future<FirebaseBingoGame?> getBingoGameById(String gameId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$gameId'));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          return FirebaseBingoGame.fromMap(responseData['data']);
        } else {
          throw Exception('Error del servidor: ${responseData['error']}');
        }
      } else if (response.statusCode == 404) {
        return null; // Juego no encontrado
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Error obteniendo juego de bingo: $e');
      rethrow;
    }
  }

  /// Crear un nuevo juego de bingo
  Future<FirebaseBingoGame> createBingoGame(FirebaseBingoGame game) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': game.name,
          'date': game.date,
          'rounds': game.rounds.map((round) => {
            'name': round.name,
            'patterns': round.patterns,
            'isCompleted': round.isCompleted,
          }).toList(),
          'totalCartillas': game.totalCartillas,
        }),
      );
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          return FirebaseBingoGame.fromMap(responseData['data']);
        } else {
          throw Exception('Error del servidor: ${responseData['error']}');
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Error creando juego de bingo: $e');
      rethrow;
    }
  }

  /// Actualizar un juego existente
  Future<void> updateBingoGame(FirebaseBingoGame game) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/${game.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': game.name,
          'date': game.date,
          'rounds': game.rounds.map((round) => {
            'id': round.id,
            'name': round.name,
            'patterns': round.patterns,
            'isCompleted': round.isCompleted,
            'createdAt': round.createdAt.toIso8601String(),
            'updatedAt': round.updatedAt.toIso8601String(),
          }).toList(),
          'totalCartillas': game.totalCartillas,
          'isCompleted': game.isCompleted,
        }),
      );
      
      if (response.statusCode != 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        throw Exception('Error del servidor: ${responseData['error']}');
      }
    } catch (e) {
      print('ERROR: Error actualizando juego de bingo: $e');
      rethrow;
    }
  }

  /// Eliminar un juego
  Future<void> deleteBingoGame(String gameId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/$gameId'));
      
      if (response.statusCode != 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Error eliminando juego de bingo: $e');
      rethrow;
    }
  }

  /// Agregar una ronda a un juego
  Future<FirebaseBingoRound> addRound(String gameId, FirebaseBingoRound round) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$gameId/rounds'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': round.name,
          'patterns': round.patterns,
          'isCompleted': round.isCompleted,
        }),
      );
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true) {
          return FirebaseBingoRound.fromMap(responseData['data']);
        } else {
          throw Exception('Error del servidor: ${responseData['error']}');
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Error agregando ronda: $e');
      rethrow;
    }
  }

  /// Actualizar una ronda
  Future<void> updateRound(String gameId, String roundId, FirebaseBingoRound round) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$gameId/rounds/$roundId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': round.name,
          'patterns': round.patterns,
          'isCompleted': round.isCompleted,
        }),
      );
      
      if (response.statusCode != 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        throw Exception('Error del servidor: ${responseData['error']}');
      }
    } catch (e) {
      print('ERROR: Error actualizando ronda: $e');
      rethrow;
    }
  }

  /// Eliminar una ronda
  Future<void> deleteRound(String gameId, String roundId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/$gameId/rounds/$roundId'));
      
      if (response.statusCode != 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Error eliminando ronda: $e');
      rethrow;
    }
  }

  /// Sincronizar juegos locales con el backend
  Future<List<FirebaseBingoGame>> syncLocalGames(List<dynamic> localGames) async {
    try {
      print('DEBUG: Iniciando sincronización de ${localGames.length} juegos locales con el backend');
      
      final List<FirebaseBingoGame> syncedGames = [];
      
      for (final localGame in localGames) {
        try {
          final firebaseGame = FirebaseBingoGame.fromLocalGame(localGame);
          final syncedGame = await createBingoGame(firebaseGame);
          syncedGames.add(syncedGame);
        } catch (e) {
          print('ERROR: Error sincronizando juego local: $e');
        }
      }
      
      print('DEBUG: Sincronización completada. ${syncedGames.length} juegos sincronizados');
      return syncedGames;
    } catch (e) {
      print('ERROR: Error en sincronización general: $e');
      rethrow;
    }
  }
}
