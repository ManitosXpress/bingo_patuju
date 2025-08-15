import { Router } from 'express';
import { z } from 'zod';
import { db } from '../index';
const vendorSchema = z.object({
    name: z.string().min(2),
    phone: z.string().min(6).optional(),
    role: z.enum(['LEADER', 'SELLER']),
    leaderId: z.string().optional(),
});
export const router = Router();
const updateSchema = z.object({
    name: z.string().min(2).optional(),
    phone: z.string().min(6).optional(),
    leaderId: z.string().optional(),
});
// Create vendor (leaders can only create SELLERs)
router.post('/', async (req, res) => {
    try {
        const parsed = vendorSchema.parse(req.body);
        if (parsed.role === 'SELLER' && !parsed.leaderId) {
            return res.status(400).json({ error: 'SELLER requires leaderId' });
        }
        const ref = await db.collection('vendors').add({
            name: parsed.name,
            phone: parsed.phone ?? null,
            role: parsed.role,
            leaderId: parsed.leaderId ?? null,
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
router.get('/', async (req, res) => {
    const { leaderId } = req.query;
    let q = db.collection('vendors');
    if (leaderId)
        q = q.where('leaderId', '==', leaderId);
    const snaps = await q.get();
    const vendors = snaps.docs.map((d) => ({ id: d.id, ...d.data() }));
    return res.json(vendors);
});
// Get vendor detail with team
router.get('/:id', async (req, res) => {
    const id = req.params.id;
    const doc = await db.collection('vendors').doc(id).get();
    if (!doc.exists)
        return res.status(404).json({ error: 'Vendor not found' });
    const data = { id: doc.id, ...doc.data() };
    const team = await db.collection('vendors').where('leaderId', '==', id).get();
    const sellers = team.docs.map((d) => ({ id: d.id, ...d.data() }));
    return res.json({ ...data, sellers });
});
// Update vendor (assign leader, update name/phone)
router.patch('/:id', async (req, res) => {
    try {
        const id = req.params.id;
        const parsed = updateSchema.parse(req.body);
        const ref = db.collection('vendors').doc(id);
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
export default router;
