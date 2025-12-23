import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/backend_config.dart';
import '../models/firebase_bingo_game.dart';

/// Servicio para manejar la persistencia de juegos de bingo usando el backend API
class BingoGamesService {
  /// Guardar un juego de bingo en Firebase a través del backend
  Future<String> saveBingoGame(FirebaseBingoGame game) async {
    try {
      print('DEBUG: Guardando juego ${game.name} para evento ${game.eventId}');
      
      // Usar la ruta correcta del backend: /api/bingo/:eventId/games
      final url = '${BackendConfig.apiBase}/bingo/${game.eventId}/games';
      print('DEBUG: URL del POST: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: BackendConfig.defaultHeaders,
        body: json.encode({
          'name': game.name,
          'date': game.date,
          'rounds': game.rounds.map((r) => {
            'name': r.name,
            'patterns': r.patterns,
            'isCompleted': r.isCompleted,
          }).toList(),
          'totalCartillas': game.totalCartillas,
        }),
      ).timeout(BackendConfig.connectionTimeout);
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final gameId = data['data']['id'];
        print('DEBUG: Juego guardado exitosamente con ID: $gameId');
        return gameId;
      } else {
        throw Exception('Error al guardar juego: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      print('ERROR: Error guardando juego de bingo: $e');
      print('STACK TRACE: $stackTrace');
      rethrow;
    }
  }

  /// Actualizar un juego de bingo existente
  Future<void> updateBingoGame(FirebaseBingoGame game) async {
    try {
      final response = await http.put(
        Uri.parse('${BackendConfig.apiBase}/bingo/${game.eventId}/games/${game.id}'),
        headers: BackendConfig.defaultHeaders,
        body: json.encode({
          'name': game.name,
          'rounds': game.rounds.map((r) => {
            'name': r.name,
            'patterns': r.patterns,
            'isCompleted': r.isCompleted,
          }).toList(),
          'totalCartillas': game.totalCartillas,
          'isCompleted': game.isCompleted,
        }),
      ).timeout(BackendConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        print('DEBUG: Juego actualizado exitosamente: ${game.name}');
      } else {
        throw Exception('Error al actualizar juego: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Error actualizando juego de bingo: $e');
      rethrow;
    }
  }

  /// Obtener todos los juegos de bingo para una fecha específica
  Future<List<FirebaseBingoGame>> getAllBingoGames({required String date}) async {
    try {
      final response = await http.get(
        Uri.parse('${BackendConfig.apiBase}/bingo/$date/games'),
        headers: BackendConfig.defaultHeaders,
      ).timeout(BackendConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> gamesData = data['data'];
        
        final games = gamesData.map((gameJson) {
          try {
            return FirebaseBingoGame(
              id: gameJson['id'].toString(),
              eventId: date,
              name: gameJson['name'].toString(),
              date: gameJson['date'].toString(),
              rounds: (gameJson['rounds'] as List<dynamic>).map((roundJson) {
                // Manejo robusto de patterns para evitar errores de tipo
                List<String> patternsList = [];
                if (roundJson['patterns'] != null) {
                  if (roundJson['patterns'] is List) {
                    patternsList = (roundJson['patterns'] as List).map((p) => p.toString()).toList();
                  }
                }

                return FirebaseBingoRound(
                  id: (roundJson['id'] ?? '').toString(),
                  name: (roundJson['name'] ?? '').toString(),
                  patterns: patternsList,
                  isCompleted: roundJson['isCompleted'] ?? false,
                  createdAt: roundJson['createdAt'] != null ? DateTime.tryParse(roundJson['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
                  updatedAt: roundJson['updatedAt'] != null ? DateTime.tryParse(roundJson['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
                );
              }).toList(),
              totalCartillas: gameJson['totalCartillas'] ?? 0,
              createdAt: gameJson['createdAt'] != null ? DateTime.tryParse(gameJson['createdAt'].toString()) ?? DateTime.now() : DateTime.now(),
              updatedAt: gameJson['updatedAt'] != null ? DateTime.tryParse(gameJson['updatedAt'].toString()) ?? DateTime.now() : DateTime.now(),
              isCompleted: gameJson['isCompleted'] ?? false,
            );
          } catch (e) {
            print('ERROR: Falló parseo de juego individual: $e');
            // Retornar un juego vacío o nulo en caso de error grave, 
            // pero el try-catch interno debería manejar la mayoría de casos.
            // Re-lanzar para que sea capturado por el bloque superior si es necesario
            rethrow;
          }
        }).toList();
        
        print('DEBUG: ${games.length} juegos cargados para la fecha $date');
        return games;
      } else {
        throw Exception('Error al cargar juegos: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Error cargando juegos de bingo: $e');
      return [];
    }
  }

  /// Obtener un juego de bingo específico por ID y fecha
  Future<FirebaseBingoGame?> getBingoGameById(String gameId, String date) async {
    try {
      final response = await http.get(
        Uri.parse('${BackendConfig.apiBase}/bingo/$date/games/$gameId'),
        headers: BackendConfig.defaultHeaders,
      ).timeout(BackendConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final gameJson = data['data'];
        
        return FirebaseBingoGame(
          id: gameJson['id'],
          eventId: date,
          name: gameJson['name'],
          date: gameJson['date'],
          rounds: (gameJson['rounds'] as List<dynamic>).map((roundJson) {
            return FirebaseBingoRound(
              id: roundJson['id'] ?? '',
              name: roundJson['name'],
              patterns: List<String>.from(roundJson['patterns']),
              isCompleted: roundJson['isCompleted'] ?? false,
              createdAt: DateTime.parse(roundJson['createdAt']),
              updatedAt: DateTime.parse(roundJson['updatedAt']),
            );
          }).toList(),
          totalCartillas: gameJson['totalCartillas'] ?? 0,
          createdAt: DateTime.parse(gameJson['createdAt']),
          updatedAt: DateTime.parse(gameJson['updatedAt']),
          isCompleted: gameJson['isCompleted'] ?? false,
        );
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Error al cargar juego: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Error cargando juego de bingo: $e');
      return null;
    }
  }

  /// Eliminar un juego de bingo
  Future<void> deleteBingoGame(String gameId, String date) async {
    try {
      final response = await http.delete(
        Uri.parse('${BackendConfig.apiBase}/bingo/$date/games/$gameId'),
        headers: BackendConfig.defaultHeaders,
      ).timeout(BackendConfig.connectionTimeout);
      
      if (response.statusCode == 200) {
        print('DEBUG: Juego eliminado: $gameId de la fecha $date');
      } else {
        throw Exception('Error al eliminar juego: ${response.statusCode}');
      }
    } catch (e) {
      print('ERROR: Error eliminando juego de bingo: $e');
      rethrow;
    }
  }
}
