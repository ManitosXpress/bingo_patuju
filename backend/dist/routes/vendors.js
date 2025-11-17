"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.router = void 0;
const express_1 = require("express");
const zod_1 = require("zod");
const index_1 = require("../index");
const vendorSchema = zod_1.z.object({
    name: zod_1.z.string().min(2),
    phone: zod_1.z.string().min(6).optional(),
    role: zod_1.z.enum(['LEADER', 'SELLER', 'SUBSELLER']),
    leaderId: zod_1.z.string().optional(),
    sellerId: zod_1.z.string().optional(), // Para subvendedores
});
exports.router = (0, express_1.Router)();
const updateSchema = zod_1.z.object({
    name: zod_1.z.string().min(2).optional(),
    phone: zod_1.z.string().min(6).optional(),
    leaderId: zod_1.z.string().optional(),
});
// Create vendor (leaders can only create SELLERs)
exports.router.post('/', async (req, res) => {
    try {
        const parsed = vendorSchema.parse(req.body);
        if (parsed.role === 'SELLER' && !parsed.leaderId) {
            return res.status(400).json({ error: 'SELLER requires leaderId' });
        }
        if (parsed.role === 'SUBSELLER' && !parsed.sellerId) {
            return res.status(400).json({ error: 'SUBSELLER requires sellerId' });
        }
        // Para subvendedores, obtener el leaderId del vendedor padre
        let finalLeaderId = parsed.leaderId;
        if (parsed.role === 'SUBSELLER' && parsed.sellerId) {
            const sellerDoc = await index_1.db.collection('vendors').doc(parsed.sellerId).get();
            if (!sellerDoc.exists) {
                return res.status(400).json({ error: 'Seller not found' });
            }
            const sellerData = sellerDoc.data();
            finalLeaderId = sellerData.leaderId;
        }
        const ref = await index_1.db.collection('vendors').add({
            name: parsed.name,
            phone: parsed.phone ?? null,
            role: parsed.role,
            leaderId: finalLeaderId ?? null,
            sellerId: parsed.sellerId ?? null, // Nuevo campo para subvendedores
            createdAt: Date.now(),
            isActive: true,
        });
        const snap = await ref.get();
        return res.status(201).json({ id: ref.id, ...snap.data() });
    }
    catch (err) {
        return res.status(400).json({ error: err.message });
    }
});
// List vendors (optionally by leader)
exports.router.get('/', async (req, res) => {
    const { leaderId } = req.query;
    let q = index_1.db.collection('vendors');
    if (leaderId)
        q = q.where('leaderId', '==', leaderId);
    const snaps = await q.get();
    const vendors = snaps.docs.map((d) => ({ id: d.id, ...d.data() }));
    return res.json(vendors);
});
// Get vendor detail with team
exports.router.get('/:id', async (req, res) => {
    const id = req.params.id;
    const doc = await index_1.db.collection('vendors').doc(id).get();
    if (!doc.exists)
        return res.status(404).json({ error: 'Vendor not found' });
    const data = { id: doc.id, ...doc.data() };
    const team = await index_1.db.collection('vendors').where('leaderId', '==', id).get();
    const sellers = team.docs.map((d) => ({ id: d.id, ...d.data() }));
    return res.json({ ...data, sellers });
});
// Update vendor (assign leader, update name/phone)
exports.router.patch('/:id', async (req, res) => {
    try {
        const id = req.params.id;
        const parsed = updateSchema.parse(req.body);
        const ref = index_1.db.collection('vendors').doc(id);
        const snap = await ref.get();
        if (!snap.exists)
            return res.status(404).json({ error: 'Vendor not found' });
        await ref.update(parsed);
        const updated = await ref.get();
        return res.json({ id, ...updated.data() });
    }
    catch (e) {
        return res.status(400).json({ error: e.message });
    }
});
exports.default = exports.router;
