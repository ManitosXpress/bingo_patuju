import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firebase_bingo_game.dart';

/// Servicio para manejar la persistencia de juegos de bingo en Firebase
class BingoGamesService {
  static const String _collectionName = 'bingo_games';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Guardar un juego de bingo en Firebase
  Future<String> saveBingoGame(FirebaseBingoGame game) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .doc(game.id)
          .set(game.toFirestore());
      
      print('DEBUG: Juego de bingo guardado exitosamente: ${game.name}');
      return game.id;
    } catch (e) {
      print('ERROR: Error guardando juego de bingo: $e');
      rethrow;
    }
  }

  /// Actualizar un juego de bingo existente
  Future<void> updateBingoGame(FirebaseBingoGame game) async {
    try {
      final updatedGame = game.copyWith(updatedAt: DateTime.now());
      
      await _firestore
          .collection(_collectionName)
          .doc(game.id)
          .update(updatedGame.toFirestore());
      
      print('DEBUG: Juego de bingo actualizado exitosamente: ${game.name}');
    } catch (e) {
      print('ERROR: Error actualizando juego de bingo: $e');
      rethrow;
    }
  }

  /// Obtener todos los juegos de bingo
  Future<List<FirebaseBingoGame>> getAllBingoGames() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();
      
      final games = querySnapshot.docs
          .map((doc) => FirebaseBingoGame.fromFirestore(doc))
          .toList();
      
      print('DEBUG: ${games.length} juegos de bingo cargados desde Firebase');
      return games;
    } catch (e) {
      print('ERROR: Error cargando juegos de bingo: $e');
      rethrow;
    }
  }

  /// Obtener un juego de bingo específico por ID
  Future<FirebaseBingoGame?> getBingoGameById(String gameId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(gameId)
          .get();
      
      if (doc.exists) {
        final game = FirebaseBingoGame.fromFirestore(doc);
        print('DEBUG: Juego de bingo cargado: ${game.name}');
        return game;
      } else {
        print('DEBUG: Juego de bingo no encontrado: $gameId');
        return null;
      }
    } catch (e) {
      print('ERROR: Error cargando juego de bingo: $e');
      rethrow;
    }
  }

  /// Eliminar un juego de bingo
  Future<void> deleteBingoGame(String gameId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(gameId)
          .delete();
      
      print('DEBUG: Juego de bingo eliminado: $gameId');
    } catch (e) {
      print('ERROR: Error eliminando juego de bingo: $e');
      rethrow;
    }
  }

  /// Guardar una ronda específica de un juego
  Future<void> saveRound(String gameId, FirebaseBingoRound round) async {
    try {
      final game = await getBingoGameById(gameId);
      if (game != null) {
        // Buscar si la ronda ya existe
        final existingRoundIndex = game.rounds.indexWhere((r) => r.id == round.id);
        List<FirebaseBingoRound> updatedRounds;
        
        if (existingRoundIndex >= 0) {
          // Actualizar ronda existente
          updatedRounds = List.from(game.rounds);
          updatedRounds[existingRoundIndex] = round.copyWith(updatedAt: DateTime.now());
        } else {
          // Agregar nueva ronda
          updatedRounds = [...game.rounds, round.copyWith(updatedAt: DateTime.now())];
        }
        
        // Actualizar el juego
        final updatedGame = game.copyWith(
          rounds: updatedRounds,
          updatedAt: DateTime.now(),
        );
        
        await updateBingoGame(updatedGame);
        print('DEBUG: Ronda guardada exitosamente: ${round.name}');
      }
    } catch (e) {
      print('ERROR: Error guardando ronda: $e');
      rethrow;
    }
  }

  /// Eliminar una ronda específica de un juego
  Future<void> deleteRound(String gameId, String roundId) async {
    try {
      final game = await getBingoGameById(gameId);
      if (game != null) {
        final updatedRounds = game.rounds.where((r) => r.id != roundId).toList();
        
        final updatedGame = game.copyWith(
          rounds: updatedRounds,
          updatedAt: DateTime.now(),
        );
        
        await updateBingoGame(updatedGame);
        print('DEBUG: Ronda eliminada exitosamente: $roundId');
      }
    } catch (e) {
      print('ERROR: Error eliminando ronda: $e');
      rethrow;
    }
  }

  /// Marcar una ronda como completada
  Future<void> markRoundAsCompleted(String gameId, String roundId, bool completed) async {
    try {
      final game = await getBingoGameById(gameId);
      if (game != null) {
        final updatedRounds = game.rounds.map((round) {
          if (round.id == roundId) {
            return round.copyWith(
              isCompleted: completed,
              updatedAt: DateTime.now(),
            );
          }
          return round;
        }).toList();
        
        final updatedGame = game.copyWith(
          rounds: updatedRounds,
          updatedAt: DateTime.now(),
        );
        
        await updateBingoGame(updatedGame);
        print('DEBUG: Ronda marcada como ${completed ? "completada" : "no completada"}: $roundId');
      }
    } catch (e) {
      print('ERROR: Error marcando ronda: $e');
      rethrow;
    }
  }

  /// Sincronizar juegos locales con Firebase
  Future<List<FirebaseBingoGame>> syncLocalGames(List<dynamic> localGames) async {
    try {
      print('DEBUG: Iniciando sincronización de ${localGames.length} juegos locales');
      
      final List<FirebaseBingoGame> syncedGames = [];
      
      for (final localGame in localGames) {
        try {
          final firebaseGame = FirebaseBingoGame.fromLocalGame(localGame);
          await saveBingoGame(firebaseGame);
          syncedGames.add(firebaseGame);
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

  /// Verificar si hay cambios en Firebase
  Stream<List<FirebaseBingoGame>> watchBingoGames() {
    return _firestore
        .collection(_collectionName)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FirebaseBingoGame.fromFirestore(doc))
            .toList());
  }
}
