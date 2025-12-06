import { Router } from 'express';
import { z } from 'zod';
import { db } from '../index';
import { EventStatus } from '../types/firestore';

const router = Router();

// Validation schemas
const createEventSchema = z.object({
  name: z.string().min(1, 'El nombre es requerido'),
  date: z.string().min(1, 'La fecha es requerida'),
  description: z.string().optional(),
  status: z.enum(['upcoming', 'active', 'completed']).default('upcoming'),
});

const updateEventSchema = z.object({
  name: z.string().min(1).optional(),
  date: z.string().optional(),
  description: z.string().optional(),
  status: z.enum(['upcoming', 'active', 'completed']).optional(),
});

// POST /api/events - Crear un nuevo evento
router.post('/', async (req: any, res: any) => {
  try {
    const parsed = createEventSchema.parse(req.body);

    const now = Date.now();
    const eventData = {
      name: parsed.name,
      date: parsed.date,
      description: parsed.description || '',
      status: parsed.status,
      totalCartillas: 0,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await db.collection('events').add(eventData);
    const doc = await docRef.get();
    const data = doc.data() as any;

    console.log(`✅ Evento creado: ${parsed.name} (ID: ${docRef.id})`);

    return res.status(201).json({
      id: docRef.id,
      ...data,
    });
  } catch (e: any) {
    console.error('❌ Error creando evento:', e);
    return res.status(400).json({ error: e.message });
  }
});

// GET /api/events - Obtener todos los eventos
router.get('/', async (_req: any, res: any) => {
  try {
    const { status } = _req.query as { status?: EventStatus };

    let query = db.collection('events').orderBy('date', 'desc') as any;

    if (status) {
      query = query.where('status', '==', status);
    }

    const snapshot = await query.get();

    const events = snapshot.docs.map((doc: any) => ({
      id: doc.id,
      ...doc.data(),
    }));

    console.log(`📋 ${events.length} evento(s) recuperado(s)`);

    return res.json(events);
  } catch (e: any) {
    console.error('❌ Error obteniendo eventos:', e);
    return res.status(500).json({ error: e.message });
  }
});

// GET /api/events/:id - Obtener un evento específico
router.get('/:id', async (req: any, res: any) => {
  try {
    const { id } = req.params;
    const doc = await db.collection('events').doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Evento no encontrado' });
    }

    return res.json({
      id: doc.id,
      ...doc.data(),
    });
  } catch (e: any) {
    console.error('❌ Error obteniendo evento:', e);
    return res.status(500).json({ error: e.message });
  }
});

// PUT /api/events/:id - Actualizar un evento
router.put('/:id', async (req: any, res: any) => {
  try {
    const { id } = req.params;
    const parsed = updateEventSchema.parse(req.body);

    const eventRef = db.collection('events').doc(id);
    const doc = await eventRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Evento no encontrado' });
    }

    const updateData = {
      ...parsed,
      updatedAt: Date.now(),
    };

    await eventRef.update(updateData);
    const updated = await eventRef.get();

    console.log(`✅ Evento actualizado: ${id}`);

    return res.json({
      id: updated.id,
      ...updated.data(),
    });
  } catch (e: any) {
    console.error('❌ Error actualizando evento:', e);
    return res.status(400).json({ error: e.message });
  }
});

// DELETE /api/events/:id - Eliminar un evento
router.delete('/:id', async (req: any, res: any) => {
  try {
    const { id } = req.params;
    const { deleteCards } = req.query as { deleteCards?: string };

    const eventRef = db.collection('events').doc(id);
    const doc = await eventRef.get();

    if (!doc.exists) {
      return res.status(404).json({ error: 'Evento no encontrado' });
    }

    // Eliminar subcollections (games y sus rounds)
    const gamesSnapshot = await eventRef.collection('games').get();
    const batch = db.batch();

    for (const gameDoc of gamesSnapshot.docs) {
      // Eliminar rounds de cada game
      const roundsSnapshot = await gameDoc.ref.collection('rounds').get();
      roundsSnapshot.docs.forEach(roundDoc => {
        batch.delete(roundDoc.ref);
      });

      // Eliminar el game
      batch.delete(gameDoc.ref);
    }

    // Eliminar el evento
    batch.delete(eventRef);

    await batch.commit();

    // Opcionalmente eliminar cartillas asociadas
    if (deleteCards === 'true') {
      const cardsSnapshot = await db.collection('cards')
        .where('eventId', '==', id)
        .get();

      const cardsBatch = db.batch();
      cardsSnapshot.docs.forEach(cardDoc => {
        cardsBatch.delete(cardDoc.ref);
      });

      await cardsBatch.commit();
      console.log(`🗑️ ${cardsSnapshot.size} cartilla(s) eliminada(s)`);
    }

    console.log(`✅ Evento eliminado: ${id}`);

    return res.json({
      message: 'Evento eliminado exitosamente',
      deletedGames: gamesSnapshot.size,
      deletedCards: deleteCards === 'true' ? 'yes' : 'no',
    });
  } catch (e: any) {
    console.error('❌ Error eliminando evento:', e);
    return res.status(500).json({ error: e.message });
  }
});

// GET /api/events/:id/stats - Obtener estadísticas del evento
router.get('/:id/stats', async (req: any, res: any) => {
  try {
    const { id } = req.params;

    // Verificar que el evento existe
    const eventDoc = await db.collection('events').doc(id).get();
    if (!eventDoc.exists) {
      return res.status(404).json({ error: 'Evento no encontrado' });
    }

    // Contar cartillas
    const cardsSnapshot = await db.collection('cards')
      .where('eventId', '==', id)
      .get();

    const totalCards = cardsSnapshot.size;
    const soldCards = cardsSnapshot.docs.filter(doc => doc.data().sold === true).length;
    const assignedCards = cardsSnapshot.docs.filter(doc => doc.data().assignedTo != null).length;

    // Contar juegos y rondas
    const gamesSnapshot = await db.collection('events').doc(id)
      .collection('games')
      .get();

    let totalRounds = 0;
    let completedRounds = 0;

    for (const gameDoc of gamesSnapshot.docs) {
      const roundsSnapshot = await gameDoc.ref.collection('rounds').get();
      totalRounds += roundsSnapshot.size;
      completedRounds += roundsSnapshot.docs.filter(r => r.data().isCompleted === true).length;
    }

    return res.json({
      eventId: id,
      cards: {
        total: totalCards,
        sold: soldCards,
        assigned: assignedCards,
        available: totalCards - assignedCards,
      },
      games: {
        total: gamesSnapshot.size,
        completed: gamesSnapshot.docs.filter(g => g.data().isCompleted === true).length,
      },
      rounds: {
        total: totalRounds,
        completed: completedRounds,
      },
    });
  } catch (e: any) {
    console.error('❌ Error obteniendo estadísticas:', e);
    return res.status(500).json({ error: e.message });
  }
});

export default router;
