import { Router } from 'express';
import { z } from 'zod';
import { db } from '../index';
const saleSchema = z.object({
    cardId: z.string(),
    sellerId: z.string(),
    amount: z.number().default(20),
});
export const router = Router();
router.get('/', async (req, res) => {
    const { sellerId, from, to } = req.query;
    let q = db.collection('sales');
    if (sellerId)
        q = q.where('sellerId', '==', sellerId);
    if (from)
        q = q.where('createdAt', '>=', Number(from));
    if (to)
        q = q.where('createdAt', '<=', Number(to));
    const snaps = await q.orderBy('createdAt', 'desc').limit(200).get();
    return res.json(snaps.docs.map((d) => ({ id: d.id, ...d.data() })));
});
router.post('/', async (req, res) => {
    try {
        const { cardId, sellerId, amount } = saleSchema.parse(req.body);
        // Ensure card exists and not sold
        const cardRef = db.collection('cards').doc(cardId);
        const card = await cardRef.get();
        if (!card.exists)
            return res.status(404).json({ error: 'Card not found' });
        if (card.data()?.sold)
            return res.status(400).json({ error: 'Card already sold' });
        // Get seller and leader
        const sellerRef = db.collection('vendors').doc(sellerId);
        const sellerDoc = await sellerRef.get();
        if (!sellerDoc.exists)
            return res.status(404).json({ error: 'Seller not found' });
        const seller = sellerDoc.data();
        let leaderId = seller.leaderId ?? null;
        // Commissions per spec: each sale gives 2 Bs to the seller; and 1 Bs to the leader if seller is not leader
        const sellerCommission = 2;
        const leaderCommission = seller.role === 'LEADER' ? 0 : 1;
        // Create sale
        const saleRef = await db.collection('sales').add({
            cardId,
            sellerId,
            leaderId,
            amount,
            commissions: {
                seller: sellerCommission,
                leader: leaderCommission,
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
        const saleSnap = await saleRef.get();
        return res.status(201).json({ id: saleRef.id, ...saleSnap.data() });
    }
    catch (e) {
        return res.status(400).json({ error: e.message });
    }
});
export default router;
