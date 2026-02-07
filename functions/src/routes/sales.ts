import { Router } from 'express';
import { z } from 'zod';
import { db } from '../index';

const saleSchema = z.object({
  cardId: z.string(),
  sellerId: z.string(),
  amount: z.number().default(20),
  date: z.string(), // Fecha del evento (YYYY-MM-DD)
});

export const router = Router();

router.get('/', async (req: any, res: any) => {
  const { sellerId, from, to } = req.query as { sellerId?: string; from?: string; to?: string };
  let q = db.collection('sales') as any;
  if (sellerId) q = q.where('sellerId', '==', sellerId);
  if (from) q = q.where('createdAt', '>=', Number(from));
  if (to) q = q.where('createdAt', '<=', Number(to));
  const snaps = await q.orderBy('createdAt', 'desc').limit(200).get();
  return res.json(snaps.docs.map((d: any) => ({ id: d.id, ...(d.data() as any) })));
});

router.post('/', async (req: any, res: any) => {
  try {
    const { cardId, sellerId, amount, date } = saleSchema.parse(req.body);

    await db.runTransaction(async (t) => {
      // 1. Validar Cartilla
      const cardRef = db.collection('events').doc(date).collection('cards').doc(cardId);
      const cardDoc = await t.get(cardRef);

      if (!cardDoc.exists) throw new Error('Card not found');
      const cardData = cardDoc.data() as any;
      if (cardData.sold) throw new Error('Card already sold');

      // 2. Validar Vendedor
      const sellerRef = db.collection('vendors').doc(sellerId);
      const sellerDoc = await t.get(sellerRef);
      if (!sellerDoc.exists) throw new Error('Seller not found');
      const seller = sellerDoc.data() as any;

      // 3. Calcular Comisiones
      // Reglas (Actualizado):
      // - Vendedor (SELLER): Gana 25% de comisión. Su Líder gana 10% (Diferencia).
      // - Líder (LEADER): Gana 25% de comisión (Venta directa).

      let leaderId: string | null = seller.leaderId ?? null;
      let sellerCommission = 0;
      let leaderCommission = 0;

      if (seller.role === 'LEADER') {
        // Caso B: Vende un Líder (Gana 25% de comisión)
        sellerCommission = amount * 0.25;
        leaderCommission = 0;
      } else if (seller.role === 'SELLER') {
        // Caso A: Vende un Vendedor (Gana 25% de comisión)
        sellerCommission = amount * 0.25;

        // Su líder gana la diferencia (10%)
        leaderCommission = amount * 0.10;

        // Validar que tenga líder
        if (!leaderId) throw new Error('Seller has no leader assigned');
      }

      // 4. Crear Registro de Venta
      const saleRef = db.collection('sales').doc();
      const saleData = {
        cardId,
        sellerId,
        leaderId,
        amount,
        commissions: {
          seller: sellerCommission,
          leader: leaderCommission,
        },
        createdAt: Date.now(),
        date,
      };
      t.set(saleRef, saleData);

      // 5. Actualizar Cartilla
      t.update(cardRef, { sold: true, saleId: saleRef.id });

      // 6. Registrar Balances (Comisiones)
      // Balance del Vendedor
      const sellerBalanceRef = db.collection('balances').doc();
      t.set(sellerBalanceRef, {
        vendorId: sellerId,
        type: 'COMMISSION',
        amount: sellerCommission,
        source: saleRef.id,
        createdAt: Date.now(),
        description: `Venta Cartilla ${cardData.cardNo ?? cardId}`
      });

      // Balance del Líder (si aplica)
      if (leaderCommission > 0 && leaderId) {
        const leaderBalanceRef = db.collection('balances').doc();
        t.set(leaderBalanceRef, {
          vendorId: leaderId,
          type: 'COMMISSION',
          amount: leaderCommission,
          source: saleRef.id,
          createdAt: Date.now(),
          description: `Comisión por venta de ${seller.name} (Cartilla ${cardData.cardNo ?? cardId})`
        });
      }

      return { id: saleRef.id, ...saleData };
    });

    return res.status(201).json({ message: 'Sale registered successfully' });
  } catch (e: any) {
    return res.status(400).json({ error: e.message });
  }
});

export default router;