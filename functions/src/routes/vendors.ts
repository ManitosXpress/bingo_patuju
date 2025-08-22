import { Router } from 'express';
import { z } from 'zod';
import { db } from '../index';

export type VendorRole = 'LEADER' | 'SELLER';

interface VendorDoc {
  id: string;
  name: string;
  phone?: string;
  role: VendorRole;
  leaderId?: string; // seller -> leader
  createdAt: number;
  isActive: boolean;
}

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
router.post('/', async (req: any, res: any) => {
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
  } catch (err: any) {
    return res.status(400).json({ error: err.message });
  }
});

// List vendors (optionally by leader)
router.get('/', async (req: any, res: any) => {
  const { leaderId } = req.query as { leaderId?: string };
  let q = db.collection('vendors') as any;
  if (leaderId) q = q.where('leaderId', '==', leaderId);
  const snaps = await q.get();
  const vendors: VendorDoc[] = snaps.docs.map((d: any) => ({ id: d.id, ...(d.data() as any) }));
  return res.json(vendors);
});

// Get vendor detail with team
router.get('/:id', async (req: any, res: any) => {
  const id = req.params.id;
  const doc = await db.collection('vendors').doc(id).get();
  if (!doc.exists) return res.status(404).json({ error: 'Vendor not found' });
  const data = { id: doc.id, ...(doc.data() as any) } as VendorDoc;
  const team = await db.collection('vendors').where('leaderId', '==', id).get();
  const sellers = team.docs.map((d: any) => ({ id: d.id, ...(d.data() as any) }));
  return res.json({ ...data, sellers });
});

// Update vendor (assign leader, update name/phone)
router.patch('/:id', async (req: any, res: any) => {
  try {
    const id = req.params.id;
    const parsed = updateSchema.parse(req.body);
    const ref = db.collection('vendors').doc(id);
    const snap = await ref.get();
    if (!snap.exists) return res.status(404).json({ error: 'Vendor not found' });
    await ref.update(parsed);
    const updated = await ref.get();
    return res.json({ id, ...(updated.data() as any) });
  } catch (e: any) {
    return res.status(400).json({ error: e.message });
  }
});

// Delete vendor
router.delete('/:id', async (req: any, res: any) => {
  try {
    const id = req.params.id;
    const vendorRef = db.collection('vendors').doc(id);
    const vendorSnap = await vendorRef.get();
    
    if (!vendorSnap.exists) {
      return res.status(404).json({ error: 'Vendor not found' });
    }
    
    const vendorData = vendorSnap.data() as any;
    const vendorRole = vendorData.role;
    const vendorId = vendorSnap.id;
    
    // Si es un líder, verificar que no tenga vendedores asignados
    if (vendorRole === 'LEADER') {
      const sellersQuery = await db.collection('vendors').where('leaderId', '==', vendorId).get();
      if (!sellersQuery.empty) {
        return res.status(400).json({ 
          error: 'Cannot delete leader with assigned sellers. Reassign or delete sellers first.' 
        });
      }
    }
    
    // Si es un vendedor, verificar que no tenga cartillas asignadas
    if (vendorRole === 'SELLER') {
      const cardsQuery = await db.collection('cards').where('assignedTo', '==', vendorId).get();
      if (!cardsQuery.empty) {
        return res.status(400).json({ 
          error: 'Cannot delete seller with assigned cards. Reassign or sell cards first.' 
        });
      }
    }
    
    // Verificar que no tenga ventas registradas
    const salesQuery = await db.collection('sales').where('sellerId', '==', vendorId).get();
    if (!salesQuery.empty) {
      return res.status(400).json({ 
        error: 'Cannot delete vendor with sales history. Sales records must be preserved.' 
        });
    }
    
    // Eliminar el vendor
    await vendorRef.delete();
    
    return res.json({ 
      message: 'Vendor deleted successfully',
      deletedVendor: {
        id: vendorId,
        name: vendorData.name,
        role: vendorData.role
      }
    });
    
  } catch (e: any) {
    return res.status(500).json({ error: e.message });
  }
});

export default router; 