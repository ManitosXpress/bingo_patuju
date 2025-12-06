import express from 'express';
import { db } from '../index';
import {
  BingoGame,
  CreateBingoGameRequest,
  UpdateBingoGameRequest,
  CreateRoundRequest,
  UpdateRoundRequest
} from '../types/bingo';

const router = express.Router();

// GET /api/events/:eventId/games - Obtener todos los juegos de un evento
router.get('/:eventId/games', async (req, res) => {
  try {
    const { eventId } = req.params;

    // Verificar que el evento existe
    const eventDoc = await db.collection('events').doc(eventId).get();
    if (!eventDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Evento no encontrado'
      });
    }

    const snapshot = await db
      .collection('events')
      .doc(eventId)
      .collection('games')
      .orderBy('createdAt', 'desc')
      .get();

    const games: BingoGame[] = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      games.push({
        id: doc.id,
        name: data.name || '',
        date: data.date || '',
        rounds: data.rounds || [],
        totalCartillas: data.totalCartillas || 0,
        createdAt: data.createdAt?.toDate() || new Date(),
        updatedAt: data.updatedAt?.toDate() || new Date(),
        isCompleted: data.isCompleted || false,
      });
    });

    return res.json({
      success: true,
      data: games,
      count: games.length
    });
  } catch (error) {
    console.error('Error getting bingo games:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// GET /api/events/:eventId/games/:gameId - Obtener un juego específico
router.get('/:eventId/games/:gameId', async (req, res) => {
  try {
    const { eventId, gameId } = req.params;

    const doc = await db
      .collection('events')
      .doc(eventId)
      .collection('games')
      .doc(gameId)
      .get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Juego de bingo no encontrado'
      });
    }

    const data = doc.data()!;
    const game: BingoGame = {
      id: doc.id,
      name: data.name || '',
      date: data.date || '',
      rounds: data.rounds || [],
      totalCartillas: data.totalCartillas || 0,
      createdAt: data.createdAt?.toDate() || new Date(),
      updatedAt: data.updatedAt?.toDate() || new Date(),
      isCompleted: data.isCompleted || false,
    };

    return res.json({
      success: true,
      data: game
    });
  } catch (error) {
    console.error('Error getting bingo game:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// POST /api/events/:eventId/games - Crear un nuevo juego en un evento
router.post('/:eventId/games', async (req, res) => {
  try {
    const { eventId } = req.params;
    const gameData: CreateBingoGameRequest = req.body;

    // Verificar que el evento existe
    const eventDoc = await db.collection('events').doc(eventId).get();
    if (!eventDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Evento no encontrado'
      });
    }

    // Validar datos requeridos
    if (!gameData.name || !gameData.date) {
      return res.status(400).json({
        success: false,
        error: 'Nombre y fecha son requeridos'
      });
    }

    const now = new Date();
    const newGame = {
      name: gameData.name,
      date: gameData.date,
      rounds: gameData.rounds.map((round) => ({
        ...round,
        id: Math.random().toString(36).substr(2, 9), // ID temporal
        createdAt: now,
        updatedAt: now,
      })),
      totalCartillas: gameData.totalCartillas || 0,
      createdAt: now,
      updatedAt: now,
      isCompleted: false,
    };

    const docRef = await db
      .collection('events')
      .doc(eventId)
      .collection('games')
      .add(newGame);

    console.log(`✅ Juego creado en evento ${eventId}: ${gameData.name}`);

    return res.status(201).json({
      success: true,
      data: {
        id: docRef.id,
        ...newGame
      },
      message: 'Juego de bingo creado exitosamente'
    });
  } catch (error) {
    console.error('Error creating bingo game:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// PUT /api/events/:eventId/games/:gameId - Actualizar un juego
router.put('/:eventId/games/:gameId', async (req, res) => {
  try {
    const { eventId, gameId } = req.params;
    const updateData: UpdateBingoGameRequest = req.body;

    const docRef = db
      .collection('events')
      .doc(eventId)
      .collection('games')
      .doc(gameId);

    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Juego de bingo no encontrado'
      });
    }

    const updatePayload = {
      ...updateData,
      updatedAt: new Date()
    };

    await docRef.update(updatePayload);

    console.log(`✅ Juego actualizado: ${gameId}`);

    return res.json({
      success: true,
      message: 'Juego de bingo actualizado exitosamente'
    });
  } catch (error) {
    console.error('Error updating bingo game:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// DELETE /api/events/:eventId/games/:gameId - Eliminar un juego
router.delete('/:eventId/games/:gameId', async (req, res) => {
  try {
    const { eventId, gameId } = req.params;

    const docRef = db
      .collection('events')
      .doc(eventId)
      .collection('games')
      .doc(gameId);

    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Juego de bingo no encontrado'
      });
    }

    // Eliminar rounds del juego primero
    const roundsSnapshot = await docRef.collection('rounds').get();
    const batch = db.batch();

    roundsSnapshot.docs.forEach(roundDoc => {
      batch.delete(roundDoc.ref);
    });

    // Eliminar el juego
    batch.delete(docRef);
    await batch.commit();

    console.log(`🗑️ Juego eliminado: ${gameId} (${roundsSnapshot.size} rondas)`);

    return res.json({
      success: true,
      message: 'Juego de bingo eliminado exitosamente',
      deletedRounds: roundsSnapshot.size
    });
  } catch (error) {
    console.error('Error deleting bingo game:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// POST /api/events/:eventId/games/:gameId/rounds - Agregar una ronda a un juego
router.post('/:eventId/games/:gameId/rounds', async (req, res) => {
  try {
    const { eventId, gameId } = req.params;
    const roundData: CreateRoundRequest = req.body;

    if (!roundData.name || !roundData.patterns) {
      return res.status(400).json({
        success: false,
        error: 'Nombre y patrones son requeridos'
      });
    }

    const gameRef = db
      .collection('events')
      .doc(eventId)
      .collection('games')
      .doc(gameId);

    const gameDoc = await gameRef.get();

    if (!gameDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Juego de bingo no encontrado'
      });
    }

    const now = new Date();
    const newRound = {
      id: Math.random().toString(36).substr(2, 9),
      name: roundData.name,
      patterns: roundData.patterns,
      isCompleted: roundData.isCompleted || false,
      createdAt: now,
      updatedAt: now,
    };

    // Usar subcollection para rounds
    const roundRef = await gameRef.collection('rounds').add(newRound);

    // Actualizar timestamp del juego
    await gameRef.update({ updatedAt: now });

    console.log(`✅ Ronda creada en juego ${gameId}: ${roundData.name}`);

    const { id: _tempId, ...roundWithoutId } = newRound;

    return res.status(201).json({
      success: true,
      data: {
        id: roundRef.id,
        ...roundWithoutId
      },
      message: 'Ronda agregada exitosamente'
    });
  } catch (error) {
    console.error('Error adding round:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// PUT /api/events/:eventId/games/:gameId/rounds/:roundId - Actualizar una ronda
router.put('/:eventId/games/:gameId/rounds/:roundId', async (req, res) => {
  try {
    const { eventId, gameId, roundId } = req.params;
    const updateData: UpdateRoundRequest = req.body;

    const roundRef = db
      .collection('events')
      .doc(eventId)
      .collection('games')
      .doc(gameId)
      .collection('rounds')
      .doc(roundId);

    const roundDoc = await roundRef.get();

    if (!roundDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Ronda no encontrada'
      });
    }

    const updatePayload = {
      ...updateData,
      updatedAt: new Date()
    };

    await roundRef.update(updatePayload);

    // Actualizar timestamp del juego padre
    await db
      .collection('events')
      .doc(eventId)
      .collection('games')
      .doc(gameId)
      .update({ updatedAt: new Date() });

    console.log(`✅ Ronda actualizada: ${roundId}`);

    return res.json({
      success: true,
      message: 'Ronda actualizada exitosamente'
    });
  } catch (error) {
    console.error('Error updating round:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// DELETE /api/events/:eventId/games/:gameId/rounds/:roundId - Eliminar una ronda
router.delete('/:eventId/games/:gameId/rounds/:roundId', async (req, res) => {
  try {
    const { eventId, gameId, roundId } = req.params;

    const roundRef = db
      .collection('events')
      .doc(eventId)
      .collection('games')
      .doc(gameId)
      .collection('rounds')
      .doc(roundId);

    const roundDoc = await roundRef.get();

    if (!roundDoc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Ronda no encontrada'
      });
    }

    await roundRef.delete();

    // Actualizar timestamp del juego padre
    await db
      .collection('events')
      .doc(eventId)
      .collection('games')
      .doc(gameId)
      .update({ updatedAt: new Date() });

    console.log(`🗑️ Ronda eliminada: ${roundId}`);

    return res.json({
      success: true,
      message: 'Ronda eliminada exitosamente'
    });
  } catch (error) {
    console.error('Error deleting round:', error);
    return res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

export { router as bingoRouter };
