"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.router = void 0;
const express_1 = require("express");
const zod_1 = require("zod");
const index_1 = require("../index");
const saleSchema = zod_1.z.object({
    cardId: zod_1.z.string(),
    sellerId: zod_1.z.string(),
    amount: zod_1.z.number().default(20),
});
exports.router = (0, express_1.Router)();
exports.router.get('/', async (req, res) => {
    const { sellerId, from, to } = req.query;
    let q = index_1.db.collection('sales');
    if (sellerId)
        q = q.where('sellerId', '==', sellerId);
    if (from)
        q = q.where('createdAt', '>=', Number(from));
    if (to)
        q = q.where('createdAt', '<=', Number(to));
    const snaps = await q.orderBy('createdAt', 'desc').limit(200).get();
    return res.json(snaps.docs.map((d) => ({ id: d.id, ...d.data() })));
});
exports.router.post('/', async (req, res) => {
    try {
        const { cardId, sellerId, amount } = saleSchema.parse(req.body);
        // Ensure card exists and not sold
        const cardRef = index_1.db.collection('cards').doc(cardId);
        const card = await cardRef.get();
        if (!card.exists)
            return res.status(404).json({ error: 'Card not found' });
        if (card.data()?.sold)
            return res.status(400).json({ error: 'Card already sold' });
        // Get seller and leader
        const sellerRef = index_1.db.collection('vendors').doc(sellerId);
        const sellerDoc = await sellerRef.get();
        if (!sellerDoc.exists)
            return res.status(404).json({ error: 'Seller not found' });
        const seller = sellerDoc.data();
        let leaderId = seller.leaderId ?? null;
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
        }
        else if (seller.role === 'SELLER') {
            // Vendedor vendiendo - líder recibe 1.5 Bs
            leaderCommission = 1.5;
        }
        else if (seller.role === 'SUBSELLER') {
            // Subvendedor vendiendo - vendedor recibe 1.5 Bs, líder recibe 1.5 Bs
            leaderCommission = 1.5; // Para el líder
            subleaderCommission = 1.5; // Para el vendedor padre
        }
        // Obtener el vendedor padre si es un subvendedor
        let subleaderId = null;
        if (seller.role === 'SUBSELLER') {
            // Buscar el vendedor padre (SELLER) que tiene este subvendedor
            const subleaderQuery = await index_1.db.collection('vendors')
                .where('role', '==', 'SELLER')
                .where('leaderId', '==', leaderId)
                .get();
            if (!subleaderQuery.empty) {
                // Asumimos que el subvendedor pertenece al primer vendedor encontrado
                // En un sistema más complejo, necesitaríamos un campo específico
                subleaderId = subleaderQuery.docs[0].id;
            }
        }
        // Create sale
        const saleRef = await index_1.db.collection('sales').add({
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
        await index_1.db.collection('balances').add({
            vendorId: sellerId,
            type: 'COMMISSION',
            amount: sellerCommission,
            source: saleRef.id,
            createdAt: Date.now(),
        });
        if (leaderCommission > 0 && leaderId) {
            await index_1.db.collection('balances').add({
                vendorId: leaderId,
                type: 'COMMISSION',
                amount: leaderCommission,
                source: saleRef.id,
                createdAt: Date.now(),
            });
        }
        if (subleaderCommission > 0 && subleaderId) {
            await index_1.db.collection('balances').add({
                vendorId: subleaderId,
                type: 'COMMISSION',
                amount: subleaderCommission,
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
exports.default = exports.router;
