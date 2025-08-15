import { Router } from 'express';
import { z } from 'zod';
import { db } from '../index';
const createCardSchema = z.object({
    numbers: z.array(z.array(z.number())),
    cardNo: z.number().int().positive().optional(),
});
const assignSchema = z.object({
    vendorId: z.string(),
});
function flattenGrid(grid) {
    const flat = [];
    for (const row of grid) {
        for (const n of row)
            flat.push(n);
    }
    return flat;
}
function expandGrid(flat, size = 5) {
    const grid = [];
    for (let r = 0; r < size; r++) {
        grid.push(flat.slice(r * size, (r + 1) * size));
    }
    return grid;
}
// Función para generar números aleatorios de Bingo según las reglas BINGO
function generateRandomBingoNumbers() {
    const grid = [];
    // Generar números para cada columna según las reglas del BINGO
    for (let col = 0; col < 5; col++) {
        const columnNumbers = [];
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
router.post('/', async (req, res) => {
    try {
        const parsed = createCardSchema.parse(req.body);
        const flat = flattenGrid(parsed.numbers);
        const dataToSave = {
            numbersFlat: flat,
            gridSize: parsed.numbers.length,
            assignedTo: null,
            sold: false,
            createdAt: Date.now(),
        };
        let docId;
        if (parsed.cardNo) {
            docId = String(parsed.cardNo);
            const ref = db.collection('cards').doc(docId);
            await ref.set(dataToSave, { merge: false });
            const snap = await ref.get();
            const data = snap.data();
            const numbers = expandGrid(data.numbersFlat ?? [], data.gridSize ?? 5);
            return res.status(201).json({ id: docId, numbers, assignedTo: data.assignedTo, sold: data.sold, createdAt: data.createdAt });
        }
        const ref = await db.collection('cards').add(dataToSave);
        const snap = await ref.get();
        const data = snap.data();
        const size = data.gridSize ?? 5;
        const numbers = expandGrid(data.numbersFlat ?? [], size);
        return res.status(201).json({
            id: ref.id,
            numbers,
            assignedTo: data.assignedTo,
            sold: data.sold,
            createdAt: data.createdAt,
            cardNo: data.cardNo ?? null,
        });
    }
    catch (e) {
        return res.status(400).json({ error: e.message });
    }
});
router.get('/', async (_req, res) => {
    const { assignedTo, sold, limit } = _req.query;
    let q = db.collection('cards');
    if (assignedTo)
        q = q.where('assignedTo', '==', assignedTo);
    if (sold === 'true')
        q = q.where('sold', '==', true);
    if (sold === 'false')
        q = q.where('sold', '==', false);
    // Usar el límite del query string o un valor alto por defecto
    const limitValue = limit ? parseInt(limit) : 2000;
    const snaps = await q.limit(limitValue).get();
    const out = snaps.docs.map((d) => {
        const data = d.data();
        const size = data.gridSize ?? 5;
        const numbers = data.numbers ? data.numbers : expandGrid(data.numbersFlat ?? [], size);
        return {
            id: d.id,
            numbers,
            assignedTo: data.assignedTo ?? null,
            sold: data.sold ?? false,
            createdAt: data.createdAt,
            cardNo: data.cardNo ?? null, // Agregar el número de cartilla
        };
    });
    // Ordenar por cardNo de menor a mayor
    out.sort((a, b) => {
        // Si ambos tienen cardNo, ordenar por ese valor
        if (a.cardNo != null && b.cardNo != null) {
            return a.cardNo - b.cardNo;
        }
        // Si solo uno tiene cardNo, poner primero el que sí lo tiene
        if (a.cardNo != null && b.cardNo == null)
            return -1;
        if (a.cardNo == null && b.cardNo != null)
            return 1;
        // Si ninguno tiene cardNo, mantener el orden original
        return 0;
    });
    return res.json(out);
});
router.post('/:id/assign', async (req, res) => {
    try {
        const parsed = assignSchema.parse(req.body);
        const id = req.params.id;
        const cardRef = db.collection('cards').doc(id);
        const card = await cardRef.get();
        if (!card.exists)
            return res.status(404).json({ error: 'Card not found' });
        await cardRef.update({ assignedTo: parsed.vendorId });
        const data = (await cardRef.get()).data();
        const size = data.gridSize ?? 5;
        const numbers = data.numbers ? data.numbers : expandGrid(data.numbersFlat ?? [], size);
        return res.json({
            id,
            numbers,
            assignedTo: data.assignedTo,
            sold: data.sold,
            createdAt: data.createdAt,
            cardNo: data.cardNo ?? null,
        });
    }
    catch (e) {
        return res.status(400).json({ error: e.message });
    }
});
// Endpoint para asignar múltiples cartillas por rango o números específicos
router.post('/bulk-assign', async (req, res) => {
    try {
        const { vendorId, cardNumbers, startRange, endRange, step = 10 } = req.body;
        if (!vendorId) {
            return res.status(400).json({ error: 'vendorId es requerido' });
        }
        if (!cardNumbers && (!startRange || !endRange)) {
            return res.status(400).json({
                error: 'Debe especificar cardNumbers o startRange y endRange'
            });
        }
        let targetCardNumbers = [];
        if (cardNumbers && cardNumbers.length > 0) {
            // Asignar cartillas específicas
            targetCardNumbers = cardNumbers;
        }
        else if (startRange && endRange) {
            // Generar rango de números
            if (startRange > endRange) {
                return res.status(400).json({
                    error: 'startRange debe ser menor o igual a endRange'
                });
            }
            for (let i = startRange; i <= endRange; i += step) {
                targetCardNumbers.push(i);
            }
        }
        if (targetCardNumbers.length === 0) {
            return res.status(400).json({ error: 'No se generaron números de cartilla válidos' });
        }
        if (targetCardNumbers.length > 100) {
            return res.status(400).json({
                error: 'No se pueden asignar más de 100 cartillas a la vez'
            });
        }
        console.log(`🃏 Asignando ${targetCardNumbers.length} cartilla${targetCardNumbers.length > 1 ? 's' : ''} a vendor ${vendorId}`);
        console.log(`📋 Números solicitados: ${targetCardNumbers.join(', ')}`);
        // Buscar las cartillas por cardNo
        const batch = db.batch();
        const assignedCards = [];
        const notFoundCards = [];
        for (const cardNo of targetCardNumbers) {
            // Buscar cartilla por cardNo
            const cardsSnapshot = await db.collection('cards')
                .where('cardNo', '==', cardNo)
                .where('sold', '==', false)
                .limit(1)
                .get();
            if (!cardsSnapshot.empty) {
                const cardDoc = cardsSnapshot.docs[0];
                const cardData = cardDoc.data();
                // Verificar que no esté ya asignada
                if (!cardData.assignedTo) {
                    batch.update(cardDoc.ref, { assignedTo: vendorId });
                    const size = cardData.gridSize ?? 5;
                    const numbers = cardData.numbers ?
                        cardData.numbers :
                        expandGrid(cardData.numbersFlat ?? [], size);
                    assignedCards.push({
                        id: cardDoc.id,
                        cardNo: cardData.cardNo,
                        numbers,
                        assignedTo: vendorId,
                        sold: cardData.sold,
                        createdAt: cardData.createdAt,
                    });
                }
                else {
                    notFoundCards.push({ cardNo, reason: 'Ya asignada' });
                }
            }
            else {
                notFoundCards.push({ cardNo, reason: 'No encontrada' });
            }
        }
        if (assignedCards.length > 0) {
            await batch.commit();
            console.log(`✅ Se asignaron ${assignedCards.length} cartilla${assignedCards.length > 1 ? 's' : ''} exitosamente`);
            console.log(`✅ Cartillas asignadas: ${assignedCards.map(c => c.cardNo).join(', ')}`);
        }
        if (notFoundCards.length > 0) {
            console.log(`❌ Cartillas no encontradas: ${notFoundCards.map(c => c.cardNo).join(', ')}`);
        }
        return res.status(200).json({
            message: `Asignación completada`,
            assignedCount: assignedCards.length,
            assignedCards,
            notFoundCards,
            totalRequested: targetCardNumbers.length,
            summary: {
                requested: targetCardNumbers,
                assigned: assignedCards.map(c => c.cardNo),
                notFound: notFoundCards.map(c => c.cardNo),
                assignedDetails: assignedCards.map(c => ({
                    cardNo: c.cardNo,
                    id: c.id,
                    vendorId: c.assignedTo
                }))
            }
        });
    }
    catch (e) {
        console.error('Error en asignación masiva:', e);
        return res.status(500).json({ error: 'Internal server error' });
    }
});
// Endpoint para generar cartillas automáticamente
router.post('/generate', async (req, res) => {
    try {
        const { count = 1 } = req.body;
        if (count < 1 || count > 100) {
            return res.status(400).json({
                error: 'La cantidad debe estar entre 1 y 100'
            });
        }
        console.log(`🃏 Generando ${count} cartilla${count > 1 ? 's' : ''} de Bingo...`);
        // Obtener el siguiente número de cartilla disponible
        const existingCards = await db.collection('cards').get();
        let nextCardNo = 1;
        if (!existingCards.empty) {
            const cardNumbers = [];
            existingCards.docs.forEach(doc => {
                const data = doc.data();
                if (data.cardNo && typeof data.cardNo === 'number') {
                    cardNumbers.push(data.cardNo);
                }
            });
            if (cardNumbers.length > 0) {
                nextCardNo = Math.max(...cardNumbers) + 1;
            }
        }
        const batch = db.batch();
        const generatedCards = [];
        for (let i = 0; i < count; i++) {
            const numbers = generateRandomBingoNumbers();
            const flat = flattenGrid(numbers);
            const dataToSave = {
                numbersFlat: flat,
                gridSize: 5,
                assignedTo: null,
                sold: false,
                createdAt: Date.now(),
                cardNo: nextCardNo + i, // Número secuencial de cartilla
            };
            const cardRef = db.collection('cards').doc();
            batch.set(cardRef, dataToSave);
            generatedCards.push({
                id: cardRef.id,
                numbers,
                assignedTo: null,
                sold: false,
                createdAt: dataToSave.createdAt,
                cardNo: dataToSave.cardNo,
            });
        }
        await batch.commit();
        console.log(`✅ Se generaron ${count} cartilla${count > 1 ? 's' : ''} exitosamente`);
        return res.status(201).json({
            message: `Se generaron ${count} cartilla${count > 1 ? 's' : ''} exitosamente`,
            count,
            cards: generatedCards
        });
    }
    catch (e) {
        console.error('Error generando cartillas:', e);
        return res.status(500).json({ error: 'Internal server error' });
    }
});
// Endpoint para eliminar TODAS las cartillas (DEBE ir ANTES de /:id)
router.delete('/clear', async (_req, res) => {
    try {
        console.log('⚠️ ADVERTENCIA: Eliminando TODAS las cartillas de la base de datos...');
        // Obtener todas las cartillas
        const allCards = await db.collection('cards').get();
        const batch = db.batch();
        // Agregar todas las cartillas al batch de eliminación
        allCards.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });
        // Ejecutar el batch
        await batch.commit();
        const deletedCount = allCards.docs.length;
        console.log(`✅ Se eliminaron ${deletedCount} cartillas de la base de datos`);
        return res.status(200).json({
            message: `Se eliminaron ${deletedCount} cartillas correctamente`,
            deletedCount
        });
    }
    catch (e) {
        console.error('Error eliminando todas las cartillas:', e);
        return res.status(500).json({ error: 'Internal server error' });
    }
});
// Endpoint para eliminar una cartilla
router.delete('/:id', async (req, res) => {
    try {
        const id = req.params.id;
        const cardRef = db.collection('cards').doc(id);
        const card = await cardRef.get();
        if (!card.exists) {
            return res.status(404).json({ error: 'Card not found' });
        }
        await cardRef.delete();
        return res.status(200).json({ message: 'Card deleted successfully', id });
    }
    catch (e) {
        console.error('Error deleting card:', e);
        return res.status(500).json({ error: 'Internal server error' });
    }
});
// Endpoint para desasignar una cartilla
router.post('/:id/unassign', async (req, res) => {
    try {
        const id = req.params.id;
        const cardRef = db.collection('cards').doc(id);
        const card = await cardRef.get();
        if (!card.exists) {
            return res.status(404).json({ error: 'Card not found' });
        }
        await cardRef.update({ assignedTo: null });
        const data = (await cardRef.get()).data();
        const size = data.gridSize ?? 5;
        const numbers = data.numbers ? data.numbers : expandGrid(data.numbersFlat ?? [], size);
        return res.json({
            id,
            numbers,
            assignedTo: data.assignedTo,
            sold: data.sold,
            createdAt: data.createdAt
        });
    }
    catch (e) {
        console.error('Error unassigning card:', e);
        return res.status(500).json({ error: 'Internal server error' });
    }
});
// Endpoint para marcar cartilla como vendida
router.post('/:id/sold', async (req, res) => {
    try {
        const id = req.params.id;
        const cardRef = db.collection('cards').doc(id);
        const card = await cardRef.get();
        if (!card.exists) {
            return res.status(404).json({ error: 'Card not found' });
        }
        await cardRef.update({ sold: true });
        const data = (await cardRef.get()).data();
        const size = data.gridSize ?? 5;
        const numbers = data.numbers ? data.numbers : expandGrid(data.numbersFlat ?? [], size);
        return res.json({
            id,
            numbers,
            assignedTo: data.assignedTo,
            sold: data.sold,
            createdAt: data.createdAt
        });
    }
    catch (e) {
        console.error('Error marking card as sold:', e);
        return res.status(500).json({ error: 'Internal server error' });
    }
});
// Función para validar si una cartilla cumple con las reglas del BINGO
function validateBingoCard(numbers) {
    if (!numbers || numbers.length !== 5)
        return false;
    for (let col = 0; col < 5; col++) {
        const startNum = col * 15 + 1;
        const endNum = (col + 1) * 15;
        for (let row = 0; row < 5; row++) {
            // El centro es libre (número 0)
            if (row === 2 && col === 2) {
                if (numbers[row][col] !== 0)
                    return false;
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
router.post('/validate-and-fix', async (_req, res) => {
    try {
        console.log('🔍 Validando y corrigiendo cartillas existentes...');
        const existingCards = await db.collection('cards').get();
        let correctedCount = 0;
        let validCount = 0;
        const batch = db.batch();
        for (const doc of existingCards.docs) {
            const data = doc.data();
            const currentNumbers = data.numbers ? data.numbers : expandGrid(data.numbersFlat ?? [], 5);
            // Validar si la cartilla cumple con las reglas del BINGO
            const isValid = validateBingoCard(currentNumbers);
            if (!isValid) {
                // Generar nueva cartilla válida
                const newNumbers = generateRandomBingoNumbers();
                const newFlat = flattenGrid(newNumbers);
                batch.update(doc.ref, {
                    numbersFlat: newFlat,
                    updatedAt: Date.now(),
                    wasCorrected: true,
                });
                correctedCount++;
            }
            else {
                validCount++;
            }
        }
        if (correctedCount > 0) {
            await batch.commit();
            console.log(`✅ Se corrigieron ${correctedCount} cartillas, ${validCount} ya eran válidas`);
        }
        else {
            console.log(`✅ Todas las cartillas ya son válidas (${validCount} cartillas)`);
        }
        return res.status(200).json({
            message: 'Validación y corrección completada',
            corrected: correctedCount,
            valid: validCount,
            total: correctedCount + validCount,
        });
    }
    catch (e) {
        console.error('❌ Error validando cartillas:', e);
        return res.status(500).json({ error: e.message });
    }
});
export default router;
