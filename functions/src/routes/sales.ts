import { Router } from 'express';
import { z } from 'zod';
import * as admin from 'firebase-admin';

const saleSchema = z.object({
  cardId: z.string(),
  sellerId: z.string(),
  amount: z.number().default(20),
  date: z.string(), // Fecha del evento (YYYY-MM-DD)
});

export const router = Router();

router.get('/', async (req: any, res: any) => {
  const db = admin.firestore();
  const { sellerId, from, to } = req.query as { sellerId?: string; from?: string; to?: string };
  let q = db.collection('sales') as any;
  if (sellerId) q = q.where('sellerId', '==', sellerId);
  if (from) q = q.where('createdAt', '>=', Number(from));
  if (to) q = q.where('createdAt', '<=', Number(to));
  const snaps = await q.orderBy('createdAt', 'desc').limit(200).get();
  return res.json(snaps.docs.map((d: any) => ({ id: d.id, ...(d.data() as any) })));
});

router.post('/', async (req: any, res: any) => {
  const db = admin.firestore();
  try {
    const { cardId, sellerId, amount, date } = saleSchema.parse(req.body);

    // 1. Validar Cartilla
    const cardRef = db.collection('events').doc(date).collection('cards').doc(cardId);
    const card = await cardRef.get();
    if (!card.exists) return res.status(404).json({ error: 'Card not found' });
    if ((card.data() as any)?.sold) return res.status(400).json({ error: 'Card already sold' });

    // 2. Obtener Datos del Vendedor
    const sellerRef = db.collection('vendors').doc(sellerId);
    const sellerDoc = await sellerRef.get();
    if (!sellerDoc.exists) return res.status(404).json({ error: 'Seller not found' });
    const seller = sellerDoc.data() as any;

    let leaderId: string | null = seller.leaderId ?? null;
    let subleaderId: string | null = null; // Vendedor padre de un subvendedor

    // 3. CÁLCULO DE COMISIONES (Lógica Porcentual)
    // Base: amount (precio de la cartilla)

    let sellerCommission = 0;    // Comisión para quien realiza la venta (Líder, Vendedor o Sub)
    let leaderCommission = 0;    // Comisión pasiva para el Líder
    let subleaderCommission = 0; // Comisión pasiva para el Vendedor Padre (si aplica)

    if (seller.role === 'LEADER') {
      // CASO 1: LÍDER vende directo
      // Gana 25% de su venta. Nadie gana pasivo.
      sellerCommission = amount * 0.25;
      leaderCommission = 0;

    } else if (seller.role === 'SELLER') {
      // CASO 2: VENDEDOR vende
      // Gana 25%. Su Líder gana 10% pasivo.
      sellerCommission = amount * 0.25;
      leaderCommission = amount * 0.10;

    } else if (seller.role === 'SUBSELLER') {
      // CASO 3: SUBVENDEDOR vende
      // Gana 25%. Su Vendedor Padre (Sublíder) gana 10% pasivo.
      // El Líder principal NO recibe en este nivel según lógica actual.
      sellerCommission = amount * 0.25;

      if (seller.sellerId) {
        subleaderId = seller.sellerId;
        subleaderCommission = amount * 0.10;
      }
    }

    // 4. Crear la Venta
    const saleRef = await db.collection('sales').add({
      cardId,
      sellerId,
      leaderId,
      subleaderId,
      amount,
      commissions: {
        seller: sellerCommission,
        leader: leaderCommission,
        subleader: subleaderCommission,
      },
      createdAt: Date.now(),
      date,
    });

    // 5. Actualizar Cartilla
    await cardRef.update({ sold: true, saleId: saleRef.id });

    // 6. Registrar Balances (Billetera)

    // Pago al Vendedor Directo
    await db.collection('balances').add({
      vendorId: sellerId,
      type: 'COMMISSION',
      amount: sellerCommission,
      source: saleRef.id,
      createdAt: Date.now(),
    });

    // Pago Pasivo al Líder (si aplica)
    if (leaderCommission > 0 && leaderId) {
      await db.collection('balances').add({
        vendorId: leaderId,
        type: 'COMMISSION',
        amount: leaderCommission,
        source: saleRef.id,
        createdAt: Date.now(),
      });
    }

    // Pago Pasivo al Sublíder (si aplica)
    if (subleaderCommission > 0 && subleaderId) {
      await db.collection('balances').add({
        vendorId: subleaderId,
        type: 'COMMISSION',
        amount: subleaderCommission,
        source: saleRef.id,
        createdAt: Date.now(),
      });
    }

    const saleSnap = await saleRef.get();
    return res.status(201).json({ id: saleRef.id, ...(saleSnap.data() as any) });
  } catch (e: any) {
    return res.status(400).json({ error: e.message });
  }
});