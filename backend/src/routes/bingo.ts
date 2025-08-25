import express from 'express';
import { db } from '../index.js';
import admin from 'firebase-admin';
import { 
  BingoGame, 
  CreateBingoGameRequest, 
  UpdateBingoGameRequest,
  CreateRoundRequest,
  UpdateRoundRequest
} from '../types/bingo.js';

const router = express.Router();
const COLLECTION_NAME = 'bingo_games';

// GET /api/bingo - Obtener todos los juegos de bingo
router.get('/', async (req, res) => {
  try {
    const snapshot = await db
      .collection(COLLECTION_NAME)
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

    res.json({
      success: true,
      data: games,
      count: games.length
    });
  } catch (error) {
    console.error('Error getting bingo games:', error);
    res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// GET /api/bingo/:id - Obtener un juego específico
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const doc = await db.collection(COLLECTION_NAME).doc(id).get();

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

    res.json({
      success: true,
      data: game
    });
  } catch (error) {
    console.error('Error getting bingo game:', error);
    res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// POST /api/bingo - Crear un nuevo juego
router.post('/', async (req, res) => {
  try {
    const gameData: CreateBingoGameRequest = req.body;
    
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
      rounds: gameData.rounds.map(round => ({
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

    const docRef = await db.collection(COLLECTION_NAME).add(newGame);
    
    res.status(201).json({
      success: true,
      data: {
        id: docRef.id,
        ...newGame
      },
      message: 'Juego de bingo creado exitosamente'
    });
  } catch (error) {
    console.error('Error creating bingo game:', error);
    res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// PUT /api/bingo/:id - Actualizar un juego
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updateData: UpdateBingoGameRequest = req.body;

    const docRef = db.collection(COLLECTION_NAME).doc(id);
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

    res.json({
      success: true,
      message: 'Juego de bingo actualizado exitosamente'
    });
  } catch (error) {
    console.error('Error updating bingo game:', error);
    res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// DELETE /api/bingo/:id - Eliminar un juego
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const docRef = db.collection(COLLECTION_NAME).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Juego de bingo no encontrado'
      });
    }

    await docRef.delete();

    res.json({
      success: true,
      message: 'Juego de bingo eliminado exitosamente'
    });
  } catch (error) {
    console.error('Error deleting bingo game:', error);
    res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// POST /api/bingo/:id/rounds - Agregar una ronda a un juego
router.post('/:id/rounds', async (req, res) => {
  try {
    const { id } = req.params;
    const roundData: CreateRoundRequest = req.body;

    if (!roundData.name || !roundData.patterns) {
      return res.status(400).json({
        success: false,
        error: 'Nombre y patrones son requeridos'
      });
    }

    const docRef = db.collection(COLLECTION_NAME).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
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

    // Agregar la nueva ronda al array de rondas
    await docRef.update({
      rounds: admin.firestore.FieldValue.arrayUnion(newRound),
      updatedAt: now
    });

    res.status(201).json({
      success: true,
      data: newRound,
      message: 'Ronda agregada exitosamente'
    });
  } catch (error) {
    console.error('Error adding round:', error);
    res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// PUT /api/bingo/:id/rounds/:roundId - Actualizar una ronda
router.put('/:id/rounds/:roundId', async (req, res) => {
  try {
    const { id, roundId } = req.params;
    const updateData: UpdateRoundRequest = req.body;

    const docRef = db.collection(COLLECTION_NAME).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Juego de bingo no encontrado'
      });
    }

    const gameData = doc.data()!;
    const rounds = gameData.rounds || [];
    const roundIndex = rounds.findIndex((r: any) => r.id === roundId);

    if (roundIndex === -1) {
      return res.status(404).json({
        success: false,
        error: 'Ronda no encontrada'
      });
    }

    // Actualizar la ronda específica
    rounds[roundIndex] = {
      ...rounds[roundIndex],
      ...updateData,
      updatedAt: new Date()
    };

    await docRef.update({
      rounds: rounds,
      updatedAt: new Date()
    });

    res.json({
      success: true,
      message: 'Ronda actualizada exitosamente'
    });
  } catch (error) {
    console.error('Error updating round:', error);
    res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

// DELETE /api/bingo/:id/rounds/:roundId - Eliminar una ronda
router.delete('/:id/rounds/:roundId', async (req, res) => {
  try {
    const { id, roundId } = req.params;

    const docRef = db.collection(COLLECTION_NAME).doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        error: 'Juego de bingo no encontrado'
      });
    }

    const gameData = doc.data()!;
    const rounds = gameData.rounds || [];
    const filteredRounds = rounds.filter((r: any) => r.id !== roundId);

    if (filteredRounds.length === rounds.length) {
      return res.status(404).json({
        success: false,
        error: 'Ronda no encontrada'
      });
    }

    await docRef.update({
      rounds: filteredRounds,
      updatedAt: new Date()
    });

    res.json({
      success: true,
      message: 'Ronda eliminada exitosamente'
    });
  } catch (error) {
    console.error('Error deleting round:', error);
    res.status(500).json({
      success: false,
      error: 'Error interno del servidor'
    });
  }
});

export { router as bingoRouter };
