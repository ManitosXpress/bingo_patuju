import { Router } from 'express';
import { z } from 'zod';
import { db } from '../index';

const saleSchema = z.object({
  cardId: z.string(),
  sellerId: z.string(),
  amount: z.number().default(20),
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
    const { cardId, sellerId, amount } = saleSchema.parse(req.body);

    // Ensure card exists and not sold
    const cardRef = db.collection('cards').doc(cardId);
    const card = await cardRef.get();
    if (!card.exists) return res.status(404).json({ error: 'Card not found' });
    if ((card.data() as any)?.sold) return res.status(400).json({ error: 'Card already sold' });

    // Get seller and leader
    const sellerRef = db.collection('vendors').doc(sellerId);
    const sellerDoc = await sellerRef.get();
    if (!sellerDoc.exists) return res.status(404).json({ error: 'Seller not found' });
    const seller = sellerDoc.data() as any;

    let leaderId: string | null = seller.leaderId ?? null;

    // Nueva estructura de comisiones:
    // - Líder: 3 Bs por cartilla vendida directamente, 1.5 Bs por vendedor de línea
    // - Vendedor: 3 Bs por cartilla vendida directamente, 1.5 Bs por subvendedor
    // - Subvendedor: 3 Bs por cartilla vendida
    
    let sellerCommission = 3; // Todos reciben 3 Bs por venta directa
    let leaderCommission = 0;
    let subleaderCommission = 0; // Para vendedores que tienen subvendedores
    
    if (seller.role === 'LEADER') {
      // Líder vendiendo directamente - solo recibe 3 Bs
      leaderCommission = 0;
    } else if (seller.role === 'SELLER') {
      // Vendedor vendiendo - líder recibe 1.5 Bs
      leaderCommission = 1.5;
    } else if (seller.role === 'SUBSELLER') {
      // Subvendedor vendiendo - vendedor padre recibe 1.5 Bs, líder NO recibe nada
      leaderCommission = 0; // El líder NO recibe del subvendedor
      subleaderCommission = 1.5; // Para el vendedor padre
    }

    // Obtener el vendedor padre si es un subvendedor
    let subleaderId: string | null = null;
    if (seller.role === 'SUBSELLER' && seller.sellerId) {
      // Usar el sellerId directamente del subvendedor
      subleaderId = seller.sellerId;
    }

    // Create sale
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
    });

    // Update card as sold and attach saleId
    await cardRef.update({ sold: true, saleId: saleRef.id });

    // Record balances
    await db.collection('balances').add({
      vendorId: sellerId,
      type: 'COMMISSION',
      amount: sellerCommission,
      source: saleRef.id,
      createdAt: Date.now(),
    });
    
    if (leaderCommission > 0 && leaderId) {
      await db.collection('balances').add({
        vendorId: leaderId,
        type: 'COMMISSION',
        amount: leaderCommission,
        source: saleRef.id,
        createdAt: Date.now(),
      });
    }
    
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

export default router; 