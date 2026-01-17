import { Router } from 'express';
import { z } from 'zod';
import { db } from '../index';

interface CardDoc {
  id: string;
  numbers?: number[][]; // 5x5 (returned by API)
  numbersFlat?: number[]; // stored in Firestore
  gridSize?: number; // default 5
  eventId: string; // FK to event - REQUERIDO
  date?: string; // Fecha del evento (ISO 8601)
  assignedTo?: string; // vendorId
  sold: boolean;
  createdAt: number;
  cardNo?: number; // Número secuencial de cartilla
}

const createCardSchema = z.object({
  numbers: z.array(z.array(z.number())),
  eventId: z.string().min(1, 'eventId es requerido'),
  cardNo: z.number().int().positive().optional(),
});

const assignSchema = z.object({
  vendorId: z.string(),
});

function flattenGrid(grid: number[][]): number[] {
  const flat: number[] = [];
  for (const row of grid) {
    for (const n of row) flat.push(n);
  }
  return flat;
}

function expandGrid(flat: number[], size = 5): number[][] {
  const grid: number[][] = [];
  for (let r = 0; r < size; r++) {
    grid.push(flat.slice(r * size, (r + 1) * size));
  }
  return grid;
}

// Función para generar números aleatorios de Bingo según las reglas BINGO
function generateRandomBingoNumbers(): number[][] {
  const grid: number[][] = [];

  // Generar números para cada columna según las reglas del BINGO
  for (let col = 0; col < 5; col++) {
    const columnNumbers: number[] = [];
    const startNum = col * 15 + 1;
    const endNum = (col + 1) * 15;

    // Generar 5 números únicos para esta columna
    while (columnNumbers.length < 5) {
      const randomNum = Math.floor(Math.random() * (endNum - startNum + 1)) + startNum;
      if (!columnNumbers.includes(randomNum)) {
        columnNumbers.push(randomNum);
      }
    }

    // Colocar los números en la columna
    for (let row = 0; row < 5; row++) {
      if (!grid[row]) {
        grid[row] = [];
      }
      grid[row][col] = columnNumbers[row];
    }
  }

  // El centro es libre (número 0)
  grid[2][2] = 0;

  return grid;
}

export const router = Router();

router.post('/', async (req: any, res: any) => {
  try {
    const parsed = createCardSchema.parse(req.body);
    const flat = flattenGrid(parsed.numbers);
    const dataToSave = {
      numbersFlat: flat,
      gridSize: parsed.numbers.length,
      eventId: parsed.eventId,
      assignedTo: null,
      sold: false,
      createdAt: Date.now(),
    } as any;
    let docId: string;
    if (parsed.cardNo) {
      docId = String(parsed.cardNo);
      const ref = db.collection('cards').doc(docId);
      await ref.set(dataToSave, { merge: false });
      const snap = await ref.get();
      const data = snap.data() as any;
      const numbers = expandGrid((data.numbersFlat as number[]) ?? [], (data.gridSize as number) ?? 5);
      return res.status(201).json({ id: docId, numbers, assignedTo: data.assignedTo, sold: data.sold, createdAt: data.createdAt });
    }
    const ref = await db.collection('cards').add(dataToSave);
    const snap = await ref.get();
    const data = snap.data() as any;
    const size = (data.gridSize as number) ?? 5;
    const numbers = expandGrid((data.numbersFlat as number[]) ?? [], size);
    return res.status(201).json({
      id: ref.id,
      numbers,
      assignedTo: data.assignedTo,
      sold: data.sold,
      createdAt: data.createdAt,
      cardNo: data.cardNo ?? null,
    });
  } catch (e: any) {
    return res.status(400).json({ error: e.message });
  }
});

router.get('/', async (_req: any, res: any) => {
  const { assignedTo, sold, limit, date, startAfter, countOnly } = _req.query as {
    assignedTo?: string;
    sold?: string;
    limit?: string;
    date?: string;
    startAfter?: string;
    countOnly?: string;
  };

  // date es REQUERIDO ahora
  if (!date) {
    return res.status(400).json({
      error: 'El parámetro "date" es requerido (formato: YYYY-MM-DD)'
    });
  }

  // Si solo se necesita el conteo, usar count() aggregation para optimizar (1 lectura en lugar de N)
  if (countOnly === 'true') {
    let countQuery = db.collection('events').doc(date).collection('cards') as any;
    if (assignedTo) countQuery = countQuery.where('assignedTo', '==', assignedTo);
    if (sold === 'true') countQuery = countQuery.where('sold', '==', true);
    if (sold === 'false') countQuery = countQuery.where('sold', '==', false);

    // Usar count() aggregation - solo 1 lectura independientemente del número de documentos
    const countAggregation = await countQuery.count().get();
    const count = countAggregation.data().count;
    return res.json({ count });
  }

  // Nueva ruta: events/{date}/cards
  let q = db.collection('events').doc(date).collection('cards') as any;

  const hasAssignedToFilter = !!assignedTo;
  const hasSoldFilter = sold === 'true' || sold === 'false';
  const hasMultipleFilters = hasAssignedToFilter && hasSoldFilter;

  if (assignedTo) q = q.where('assignedTo', '==', assignedTo);
  if (sold === 'true') q = q.where('sold', '==', true);
  if (sold === 'false') q = q.where('sold', '==', false);

  // Si hay múltiples filtros, no usar orderBy en Firestore (requiere índice compuesto)
  // En su lugar, ordenaremos en memoria después
  let useOrderBy = !hasMultipleFilters;

  if (useOrderBy) {
    q = q.orderBy('cardNo', 'asc');
  }

  // Implementar paginación con cursor - OPTIMIZADO: límite por defecto de 50 para reducir lecturas
  const pageSize = limit ? Math.min(parseInt(limit), 2000) : 50; // Reducido de 2000 a 50 por defecto
  q = q.limit(pageSize);

  // Si hay cursor (startAfter) y no hay múltiples filtros, continuar desde ahí
  if (startAfter && useOrderBy) {
    try {
      const startAfterDoc = await db.collection('events').doc(date).collection('cards').doc(startAfter).get();
      if (startAfterDoc.exists) {
        q = q.startAfter(startAfterDoc);
      }
    } catch (e) {
      // Si el documento no existe, ignorar el cursor
    }
  }

  let snaps;
  try {
    snaps = await q.get();
  } catch (e: any) {
    // Si falla por falta de índice, intentar sin orderBy y ordenar en memoria
    if (e.message && e.message.includes('index')) {
      useOrderBy = false;
      q = db.collection('events').doc(date).collection('cards') as any;
      if (assignedTo) q = q.where('assignedTo', '==', assignedTo);
      if (sold === 'true') q = q.where('sold', '==', true);
      if (sold === 'false') q = q.where('sold', '==', false);
      q = q.limit(pageSize);
      snaps = await q.get();
    } else {
      throw e;
    }
  }

  let out = snaps.docs.map((d: any) => {
    const data = d.data();
    const size = (data.gridSize as number) ?? 5;
    const numbers = data.numbers ? (data.numbers as number[][]) : expandGrid((data.numbersFlat as number[]) ?? [], size);
    return {
      id: d.id,
      numbers,
      assignedTo: data.assignedTo ?? null,
      sold: data.sold ?? false,
      createdAt: data.createdAt,
      cardNo: data.cardNo ?? null,
      date: date, // Incluir la fecha del evento
    } as CardDoc;
  });

  // Si hay múltiples filtros o no se pudo usar orderBy, ordenar en memoria
  if (hasMultipleFilters || !useOrderBy) {
    out.sort((a: CardDoc, b: CardDoc) => {
      if (a.cardNo != null && b.cardNo != null) {
        return a.cardNo - b.cardNo;
      }
      if (a.cardNo != null && b.cardNo == null) return -1;
      if (a.cardNo == null && b.cardNo != null) return 1;
      return 0;
    });
  }

  // Determinar si hay más páginas
  const hasMore = snaps.docs.length === pageSize;
  const lastDocId = snaps.docs.length > 0 ? snaps.docs[snaps.docs.length - 1].id : null;

  return res.json({
    cards: out,
    pagination: {
      hasMore,
      lastDocId,
      pageSize: out.length,
      totalInPage: out.length
    }
  });
});

// Endpoint de búsqueda directa por número de cartilla (cardNo)
router.get('/search', async (_req: any, res: any) => {
  try {
    const { date, cardNo } = _req.query as {
      date?: string;
      cardNo?: string;
    };

    if (!date) {
      return res.status(400).json({
        error: 'El parámetro "date" es requerido (formato: YYYY-MM-DD)',
      });
    }

    if (!cardNo) {
      return res.status(400).json({
        error: 'El parámetro "cardNo" es requerido para la búsqueda',
      });
    }

    const parsedCardNo = parseInt(cardNo, 10);
    if (isNaN(parsedCardNo)) {
      return res.status(400).json({
        error: 'El parámetro "cardNo" debe ser un número válido',
      });
    }

    const cardsCollectionRef = db
      .collection('events')
      .doc(date)
      .collection('cards') as any;

    // Búsqueda directa por número de cartilla
    const snaps = await cardsCollectionRef
      .where('cardNo', '==', parsedCardNo)
      .limit(5)
      .get();

    const cards: CardDoc[] = snaps.docs.map((d: any) => {
      const data = d.data();
      const size = (data.gridSize as number) ?? 5;
      const numbers = data.numbers
        ? (data.numbers as number[][])
        : expandGrid((data.numbersFlat as number[]) ?? [], size);

      return {
        date: date, // Incluir la fecha del evento
        id: d.id,
        numbers,
        assignedTo: data.assignedTo ?? null,
        sold: data.sold ?? false,
        createdAt: data.createdAt,
        cardNo: data.cardNo ?? null,
      } as CardDoc;
    });

    return res.json({
      cards,
      pagination: {
        hasMore: false,
        lastDocId: null,
        pageSize: cards.length,
        totalInPage: cards.length,
      },
    });
  } catch (e: any) {
    return res.status(500).json({ error: e.message });
  }
});

router.post('/:id/assign', async (req: any, res: any) => {
  try {
    const parsed = assignSchema.parse(req.body);
    const id = req.params.id;
    const { date } = req.query as { date?: string };

    if (!date) {
      return res.status(400).json({ error: 'El parámetro "date" es requerido' });
    }

    // Validar el target vendor
    const vendorDoc = await db.collection('vendors').doc(parsed.vendorId).get();
    if (!vendorDoc.exists) return res.status(404).json({ error: 'Vendor not found' });
    const vendorData = vendorDoc.data() as any;

    const cardRef = db.collection('events').doc(date).collection('cards').doc(id);
    const cardSnap = await cardRef.get();
    if (!cardSnap.exists) return res.status(404).json({ error: 'Card not found' });
    const cardData = cardSnap.data() as any;

    // Lógica de asignación estricta:
    // 1. Admin -> Líder: La cartilla debe estar sin asignar (assignedTo: null) y el destino ser LEADER.
    // 2. Líder -> Vendedor: La cartilla debe estar asignada al Líder y el destino ser su SELLER.

    if (vendorData.role === 'LEADER') {
      // Asignación a Líder (desde Admin/Sistema)
      // Permitimos re-asignar si ya tiene dueño? Por seguridad, solo si es null.
      if (cardData.assignedTo && cardData.assignedTo !== parsed.vendorId) {
        // Opcional: Permitir reasignar entre líderes si es admin? 
        // Por ahora estricto: Solo si es null.
        // return res.status(400).json({ error: 'Card is already assigned. Unassign first.' });
      }
      // Aceptamos asignación a líder.
    } else if (vendorData.role === 'SELLER') {
      // Asignación a Vendedor (desde Líder)
      // La cartilla DEBE estar asignada actualmente al Leader del vendedor.
      if (cardData.assignedTo !== vendorData.leaderId) {
        return res.status(400).json({
          error: 'Invalid assignment flow. Card must be assigned to the Seller\'s Leader first.'
        });
      }
    } else {
      return res.status(400).json({ error: 'Invalid vendor role' });
    }

    await cardRef.update({ assignedTo: parsed.vendorId });
    const data = (await cardRef.get()).data() as any;
    const size = (data.gridSize as number) ?? 5;
    const numbers = data.numbers ? (data.numbers as number[][]) : expandGrid((data.numbersFlat as number[]) ?? [], size);
    return res.json({
      id,
      numbers,
      assignedTo: data.assignedTo,
      sold: data.sold,
      createdAt: data.createdAt,
      cardNo: data.cardNo ?? null,
      date: date,
    });
  } catch (e: any) {
    return res.status(400).json({ error: e.message });
  }
});

// Endpoint para asignar múltiples cartillas (por cantidad o rango)
router.post('/bulk-assign', async (req: any, res: any) => {
  try {
    const { vendorId, count, cardNumbers, startRange, endRange, step = 10, date } = req.body as {
      vendorId: string;
      count?: number;
      cardNumbers?: number[];
      startRange?: number;
      endRange?: number;
      step?: number;
      date: string;
    };

    if (!vendorId) return res.status(400).json({ error: 'vendorId es requerido' });
    if (!date) return res.status(400).json({ error: 'date es requerido' });

    // Validar el target vendor
    const vendorDoc = await db.collection('vendors').doc(vendorId).get();
    if (!vendorDoc.exists) return res.status(404).json({ error: 'Vendor not found' });
    const vendorData = vendorDoc.data() as any;

    let docsToAssign: any[] = [];
    let warningMessage = '';

    // MODO 1: Asignación por Cantidad (Mass Assignment)
    if (count && count > 0) {
      if (count > 5000) return res.status(400).json({ error: 'Máximo 5000 cartillas por operación' });

      // URGENT FIX: Admin Override & Partial Assignment
      // Buscar cartillas DISPONIBLES (sin asignar y sin vender)
      // No filtramos por jerarquía si faltan cartillas, asumimos que el Admin está asignando desde el stock global.

      let q = db.collection('events').doc(date).collection('cards')
        .where('assignedTo', '==', null)
        .where('sold', '==', false)
        .limit(count);

      // Si es un vendedor (SELLER), intentamos buscar primero de su líder.
      // PERO si el Admin está haciendo la asignación (que es el caso de uso actual), 
      // queremos que funcione incluso si el líder no tiene stock, asignando directamente del global.
      // Para simplificar y cumplir con "DESBLOQUEO TOTAL":
      // Siempre buscamos del stock global (assignedTo == null).
      // Esto asume que el Admin está repartiendo el stock inicial.

      // Si se quisiera mantener la lógica de "Seller solo recibe de Leader", se debería descomentar esto,
      // pero la instrucción es "Eliminar Restricción de Jerarquía".
      /*
      if (vendorData.role === 'SELLER' && vendorData.leaderId) {
         // Lógica opcional: intentar tomar del líder primero?
         // Por ahora, asignación directa del stock global al vendedor es lo solicitado.
      }
      */

      const snapshot = await q.get();

      if (snapshot.empty) {
        // Si no hay cartillas globales, y es un vendedor, tal vez el líder tiene?
        // Por ahora, devolvemos lo que encontramos (nada) con advertencia en vez de error.
        return res.status(200).json({
          message: 'No hay cartillas disponibles en el stock global',
          assignedCount: 0,
          warning: 'Stock agotado'
        });
      }

      docsToAssign = snapshot.docs;

      if (docsToAssign.length < count) {
        warningMessage = `Se solicitaron ${count} cartillas pero solo habían ${docsToAssign.length} disponibles. Se asignaron todas las disponibles.`;
      }
    }
    // MODO 2: Asignación por Rango o Lista (Legacy/Manual)
    else if (cardNumbers || (startRange && endRange)) {
      // ... (Mantenemos lógica existente simplificada o la adaptamos si es necesario)
      // Para este fix urgente, nos centramos en el MODO 1 que es el que usa "Block Assignment".
      // Si se usa este modo, asumimos que el admin sabe lo que hace.

      let targetCardNumbers: number[] = [];
      if (cardNumbers && cardNumbers.length > 0) {
        targetCardNumbers = cardNumbers;
      } else if (startRange && endRange) {
        for (let i = startRange; i <= endRange; i += step) {
          targetCardNumbers.push(i);
        }
      }

      // Búsqueda ineficiente pero funcional para listas manuales
      const readPromises = targetCardNumbers.map(no =>
        db.collection('events').doc(date).collection('cards')
          .where('cardNo', '==', no)
          .limit(1)
          .get()
      );

      const results = await Promise.all(readPromises);
      for (const snap of results) {
        if (!snap.empty) {
          const doc = snap.docs[0];
          const d = doc.data();
          // URGENT FIX: Permitir reasignación si es Admin (o forzar)
          // Solo verificamos que no esté vendida.
          if (!d.sold) {
            docsToAssign.push(doc);
          }
        }
      }
    } else {
      return res.status(400).json({ error: 'Debe especificar count, cardNumbers o rango' });
    }

    if (docsToAssign.length === 0) {
      return res.status(200).json({
        message: 'No se encontraron cartillas válidas para asignar',
        assignedCount: 0
      });
    }

    // PROCESAMIENTO POR LOTES (BATCH CHUNKING) - SERIAL
    const BATCH_SIZE = 499;
    const chunks = [];
    for (let i = 0; i < docsToAssign.length; i += BATCH_SIZE) {
      chunks.push(docsToAssign.slice(i, i + BATCH_SIZE));
    }

    let assignedCount = 0;

    for (const chunk of chunks) {
      const batch = db.batch();
      for (const doc of chunk) {
        batch.update(doc.ref, { assignedTo: vendorId });
      }
      await batch.commit();
      assignedCount += chunk.length;
    }

    return res.status(200).json({
      message: 'Asignación completada exitosamente',
      assignedCount,
      vendorId,
      role: vendorData.role,
      warning: warningMessage || undefined
    });

  } catch (e: any) {
    console.error('Error en bulk-assign:', e);
    return res.status(500).json({ error: 'Internal server error: ' + e.message });
  }
});

// Endpoint para generar cartillas automáticamente
router.post('/generate', async (req: any, res: any) => {
  try {
    const { count = 1, date } = req.body as { count?: number; date?: string };

    // date es REQUERIDO ahora
    if (!date) {
      return res.status(400).json({
        error: 'El parámetro "date" es requerido (formato: YYYY-MM-DD)'
      });
    }

    if (count < 0 || count > 10000) {
      return res.status(400).json({
        error: 'La cantidad debe estar entre 0 y 10000'
      });
    }

    if (count === 0) {
      return res.status(201).json({
        message: 'No se generaron cartillas (cantidad 0)',
        count: 0,
        cards: []
      });
    }

    // Nueva ruta: events/{date}/cards
    const cardsCollectionRef = db.collection('events').doc(date).collection('cards');

    // Obtener el siguiente número de cartilla en esta fecha
    let nextCardNo = 1;
    try {
      const lastCardQuery = await cardsCollectionRef
        .orderBy('cardNo', 'desc')
        .limit(1)
        .get();

      if (!lastCardQuery.empty) {
        const lastCard = lastCardQuery.docs[0].data();
        if (lastCard.cardNo && typeof lastCard.cardNo === 'number') {
          nextCardNo = lastCard.cardNo + 1;
        }
      }
    } catch (e) {
      // Si no hay índice, obtener todas las cartillas y encontrar el máximo
      // Esto es ineficiente pero necesario si no hay índice
      let allCards: any[] = [];
      let lastDoc: any = null;
      let hasMore = true;

      while (hasMore) {
        let query = cardsCollectionRef.orderBy('__name__', 'asc').limit(1000) as any;
        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const snapshot = await query.get();
        if (snapshot.empty) {
          hasMore = false;
          break;
        }

        allCards.push(...snapshot.docs.map((d: any) => d.data()));
        lastDoc = snapshot.docs[snapshot.docs.length - 1];

        if (snapshot.docs.length < 1000) {
          hasMore = false;
        }
      }

      if (allCards.length > 0) {
        const cardNumbers = allCards
          .map(d => d.cardNo)
          .filter((n): n is number => typeof n === 'number');
        if (cardNumbers.length > 0) {
          nextCardNo = Math.max(...cardNumbers) + 1;
        }
      }
    }

    // Firebase limita a 500 operaciones por batch
    const BATCH_SIZE = 500;
    const generatedCards: any[] = [];
    const totalBatches = Math.ceil(count / BATCH_SIZE);

    // Procesar en múltiples batches
    for (let batchIndex = 0; batchIndex < totalBatches; batchIndex++) {
      const batchStart = batchIndex * BATCH_SIZE;
      const batchEnd = Math.min(batchStart + BATCH_SIZE, count);
      const batchCount = batchEnd - batchStart;

      const batch = db.batch();
      const batchCards: any[] = [];

      // Generar todas las cartillas del batch en memoria primero
      for (let i = 0; i < batchCount; i++) {
        const numbers = generateRandomBingoNumbers();
        const flat = flattenGrid(numbers);
        const cardNo = nextCardNo + batchStart + i;

        const dataToSave = {
          numbersFlat: flat,
          gridSize: 5,
          assignedTo: null,
          sold: false,
          createdAt: Date.now(),
          cardNo: cardNo,
        };

        // Escribir en events/{date}/cards
        const cardRef = cardsCollectionRef.doc();
        batch.set(cardRef, dataToSave);

        batchCards.push({
          id: cardRef.id,
          numbers,
          assignedTo: null,
          sold: false,
          createdAt: dataToSave.createdAt,
          cardNo: dataToSave.cardNo,
        });
      }

      // Commit del batch
      await batch.commit();
      generatedCards.push(...batchCards);
    }

    return res.status(201).json({
      message: `Se generaron ${count} cartilla${count > 1 ? 's' : ''} exitosamente`,
      count,
      cards: generatedCards
    });

  } catch (e: any) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Endpoint para eliminar TODAS las cartillas (DEBE ir ANTES de /:id)
router.delete('/clear', async (req: any, res: any) => {
  try {
    const { date } = req.query as { date?: string };

    // date es REQUERIDO ahora
    if (!date) {
      return res.status(400).json({
        error: 'El parámetro "date" es requerido (formato: YYYY-MM-DD)'
      });
    }

    const cardsCollectionRef = db.collection('events').doc(date).collection('cards');
    const BATCH_SIZE = 500; // Límite de Firestore
    let deletedCount = 0;
    let lastDoc: any = null;
    let hasMore = true;

    // Procesar en chunks para evitar exceder el límite de 500 operaciones por batch
    while (hasMore) {
      let query = cardsCollectionRef.orderBy('__name__', 'asc').limit(BATCH_SIZE) as any;

      // Si hay un documento anterior, continuar desde ahí
      if (lastDoc) {
        query = query.startAfter(lastDoc);
      }

      const batch = db.batch();
      const snapshot = await query.get();

      if (snapshot.empty) {
        hasMore = false;
        break;
      }

      // Agregar todas las cartillas del chunk al batch
      snapshot.docs.forEach((doc: any) => {
        batch.delete(doc.ref);
        lastDoc = doc;
      });

      // Ejecutar el batch
      await batch.commit();
      deletedCount += snapshot.docs.length;

      // Si obtuvimos menos de BATCH_SIZE, no hay más documentos
      if (snapshot.docs.length < BATCH_SIZE) {
        hasMore = false;
      }
    }

    return res.status(200).json({
      message: `Se eliminaron ${deletedCount} cartillas correctamente del evento ${date}`,
      deletedCount,
      eventDate: date
    });
  } catch (e: any) {
    return res.status(500).json({ error: 'Internal server error', details: e.message });
  }
});

// Endpoint para eliminar una cartilla
router.delete('/:id', async (req: any, res: any) => {
  try {
    const id = req.params.id;
    const { date } = req.query as { date?: string };

    if (!date) {
      return res.status(400).json({ error: 'El parámetro "date" es requerido' });
    }

    const cardRef = db.collection('events').doc(date).collection('cards').doc(id);
    const card = await cardRef.get();

    if (!card.exists) {
      return res.status(404).json({ error: 'Card not found' });
    }

    await cardRef.delete();
    return res.status(200).json({ message: 'Card deleted successfully', id });
  } catch (e: any) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Endpoint para desasignar una cartilla
router.post('/:id/unassign', async (req: any, res: any) => {
  try {
    const id = req.params.id;
    const { date } = req.query as { date?: string };

    if (!date) {
      return res.status(400).json({ error: 'El parámetro "date" es requerido' });
    }

    // Nueva ruta: events/{date}/cards
    const cardRef = db.collection('events').doc(date).collection('cards').doc(id);
    const card = await cardRef.get();

    if (!card.exists) {
      return res.status(404).json({ error: 'Card not found' });
    }

    await cardRef.update({ assignedTo: null });
    const data = (await cardRef.get()).data() as any;
    const size = (data.gridSize as number) ?? 5;
    const numbers = data.numbers ? (data.numbers as number[][]) : expandGrid((data.numbersFlat as number[]) ?? [], size);

    return res.json({
      id,
      numbers,
      assignedTo: data.assignedTo,
      sold: data.sold,
      createdAt: data.createdAt,
      cardNo: data.cardNo ?? null,
      date: date, // Incluir la fecha del evento
    });
  } catch (e: any) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Endpoint para marcar cartilla como vendida
router.post('/:id/sold', async (req: any, res: any) => {
  try {
    const id = req.params.id;
    const cardRef = db.collection('cards').doc(id);
    const card = await cardRef.get();

    if (!card.exists) {
      return res.status(404).json({ error: 'Card not found' });
    }

    await cardRef.update({ sold: true });
    const data = (await cardRef.get()).data() as any;
    const size = (data.gridSize as number) ?? 5;
    const numbers = data.numbers ? (data.numbers as number[][]) : expandGrid((data.numbersFlat as number[]) ?? [], size);

    return res.json({
      id,
      numbers,
      assignedTo: data.assignedTo,
      sold: data.sold,
      createdAt: data.createdAt
    });
  } catch (e: any) {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Función para validar si una cartilla cumple con las reglas del BINGO
function validateBingoCard(numbers: number[][]): boolean {
  if (!numbers || numbers.length !== 5) return false;

  for (let col = 0; col < 5; col++) {
    const startNum = col * 15 + 1;
    const endNum = (col + 1) * 15;

    for (let row = 0; row < 5; row++) {
      // El centro es libre (número 0)
      if (row === 2 && col === 2) {
        if (numbers[row][col] !== 0) return false;
        continue;
      }

      const num = numbers[row][col];
      if (num < startNum || num > endNum) {
        return false;
      }
    }
  }

  return true;
}

// Endpoint para validar y corregir cartillas existentes según las reglas del BINGO
router.post('/validate-and-fix', async (_req: any, res: any) => {
  try {
    const existingCards = await db.collection('cards').get();
    let correctedCount = 0;
    let validCount = 0;

    const BATCH_SIZE = 500;
    const docsToUpdate: any[] = [];

    for (const doc of existingCards.docs) {
      const data = doc.data();
      const currentNumbers = data.numbers ? (data.numbers as number[][]) : expandGrid((data.numbersFlat as number[]) ?? [], 5);

      const isValid = validateBingoCard(currentNumbers);

      if (!isValid) {
        const newNumbers = generateRandomBingoNumbers();
        const newFlat = flattenGrid(newNumbers);

        docsToUpdate.push({
          ref: doc.ref,
          data: {
            numbersFlat: newFlat,
            updatedAt: Date.now(),
            wasCorrected: true,
          }
        });

        correctedCount++;
      } else {
        validCount++;
      }
    }

    // Procesar actualizaciones en batches
    for (let i = 0; i < docsToUpdate.length; i += BATCH_SIZE) {
      const batch = db.batch();
      const chunk = docsToUpdate.slice(i, i + BATCH_SIZE);

      chunk.forEach(({ ref, data }) => {
        batch.update(ref, data);
      });

      await batch.commit();
    }

    return res.status(200).json({
      message: 'Validación y corrección completada',
      corrected: correctedCount,
      valid: validCount,
      total: correctedCount + validCount,
    });
  } catch (e: any) {
    return res.status(500).json({ error: e.message });
  }
});

// Endpoint para obtener el total de cartillas y el número máximo de cartilla
router.get('/total', async (_req: any, res: any) => {
  try {
    const { date } = _req.query as { date?: string };

    if (!date) {
      return res.status(400).json({
        error: 'El parámetro "date" es requerido (formato: YYYY-MM-DD)'
      });
    }

    const cardsCollectionRef = db.collection('events').doc(date).collection('cards');

    // Obtener la cartilla con el número más alto usando orderBy (1 lectura)
    const maxCardQuery = await cardsCollectionRef
      .orderBy('cardNo', 'desc')
      .limit(1)
      .get();

    let maxCardNo = 0;
    if (!maxCardQuery.empty) {
      const maxCard = maxCardQuery.docs[0].data();
      maxCardNo = maxCard.cardNo || 0;
    }

    // Usar count() aggregation - solo 1 lectura en lugar de descargar todos los documentos
    const countAggregation = await cardsCollectionRef.count().get();
    const totalDocuments = countAggregation.data().count;

    const actualTotal = Math.max(maxCardNo, totalDocuments);

    return res.json({
      totalCards: actualTotal,
      maxCardNo: maxCardNo,
      totalDocuments: totalDocuments,
    });
  } catch (e: any) {
    return res.status(500).json({ error: e.message });
  }
});

// Endpoint optimizado para obtener conteos de cartillas asignadas para múltiples vendors
// Usa count() aggregation para reducir lecturas de 3000+ a solo 2 por vendor
router.post('/counts', async (req: any, res: any) => {
  try {
    const { vendorIds, date } = req.body as { vendorIds: string[]; date: string };

    if (!date) {
      return res.status(400).json({
        error: 'El parámetro "date" es requerido (formato: YYYY-MM-DD)'
      });
    }

    if (!vendorIds || !Array.isArray(vendorIds) || vendorIds.length === 0) {
      return res.status(400).json({
        error: 'vendorIds debe ser un array no vacío'
      });
    }

    const cardsCollectionRef = db.collection('events').doc(date).collection('cards');
    const counts: Record<string, { assigned: number; sold: number }> = {};

    // Inicializar todos los conteos en 0
    vendorIds.forEach(id => {
      counts[id] = { assigned: 0, sold: 0 };
    });

    // Usar count() aggregation en lugar de .get() para reducir lecturas drásticamente
    // De 3000+ lecturas a solo 2 por vendor (assigned y sold)
    const BATCH_SIZE = 20; // Procesar 20 vendors en paralelo
    const vendorBatches: string[][] = [];

    for (let i = 0; i < vendorIds.length; i += BATCH_SIZE) {
      vendorBatches.push(vendorIds.slice(i, i + BATCH_SIZE));
    }

    // Procesar batches en paralelo usando count() aggregation
    await Promise.all(
      vendorBatches.map(async (batch) => {
        const queries = await Promise.all(
          batch.map(async (vendorId) => {
            // Usar count() aggregation - solo 1 lectura por query en lugar de descargar todos los documentos
            const [assignedCount, soldCount] = await Promise.all([
              cardsCollectionRef
                .where('assignedTo', '==', vendorId)
                .count()
                .get(),
              cardsCollectionRef
                .where('assignedTo', '==', vendorId)
                .where('sold', '==', true)
                .count()
                .get()
            ]);

            return {
              vendorId,
              assigned: assignedCount.data().count,
              sold: soldCount.data().count
            };
          })
        );

        queries.forEach(({ vendorId, assigned, sold }) => {
          counts[vendorId] = { assigned, sold };
        });
      })
    );

    return res.json({ counts });
  } catch (e: any) {
    return res.status(500).json({ error: 'Internal server error', details: e.message });
  }
});

export default router; 