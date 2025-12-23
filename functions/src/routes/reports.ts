import { Router } from 'express';
import { db } from '../index';

export const router = Router();

// GET /reports/vendors-summary
router.get('/vendors-summary', async (req: any, res: any) => {
  const from = req.query.from ? Number(req.query.from) : undefined;
  const to = req.query.to ? Number(req.query.to) : undefined;
  const date = req.query.date as string | undefined;
  const leaderFilter: string | undefined = req.query.leaderId as string | undefined;
  // Load vendors
  const vendorSnaps = await db.collection('vendors').get();
  const vendors = new Map<string, any>();
  vendorSnaps.docs.forEach((d) => vendors.set(d.id, { id: d.id, ...(d.data() as any) }));

  // Prepare stats
  const stats: Record<string, any> = {};
  const ensure = (id: string) =>
    (stats[id] ??= {
      vendorId: id,
      name: vendors.get(id)?.name ?? '—',
      role: vendors.get(id)?.role ?? 'SELLER',
      leaderId: vendors.get(id)?.leaderId ?? null,
      soldCount: 0,
      revenueBs: 0,
      commissionsBs: 0,
      sellerCommissionBs: 0,
      leaderCommissionBs: 0,
    });

  // Iterate sales
  let q = db.collection('sales') as any;
  if (date) q = q.where('date', '==', date); // Filtrar por fecha de evento
  if (from) q = q.where('createdAt', '>=', from);
  if (to) q = q.where('createdAt', '<=', to);
  const salesSnaps = await q.get();
  salesSnaps.docs.forEach((s: any) => {
    const sale = s.data() as any;
    if (leaderFilter) {
      // keep only sales by seller under this leader or by the leader himself
      const seller = vendors.get(sale.sellerId);
      if (!(sale.leaderId === leaderFilter || sale.sellerId === leaderFilter || seller?.leaderId === leaderFilter)) {
        return;
      }
    }
    // Seller
    const sStat = ensure(sale.sellerId);
    sStat.soldCount += 1;
    sStat.revenueBs += sale.amount ?? 0;
    sStat.commissionsBs += sale.commissions?.seller ?? 0;
    sStat.sellerCommissionBs += sale.commissions?.seller ?? 0;
    
    // Leader
    if (sale.leaderId) {
      const lStat = ensure(sale.leaderId);
      lStat.commissionsBs += sale.commissions?.leader ?? 0;
      lStat.leaderCommissionBs += sale.commissions?.leader ?? 0;
    }
    
    // Subleader (vendedor padre de subvendedores)
    if (sale.subleaderId) {
      const slStat = ensure(sale.subleaderId);
      slStat.commissionsBs += sale.commissions?.subleader ?? 0;
      slStat.subleaderCommissionBs = (slStat.subleaderCommissionBs ?? 0) + (sale.commissions?.subleader ?? 0);
    }
  });

  // Attach children (sellers under leaders and subsellers under sellers)
  const byLeader: Record<string, string[]> = {};
  
  vendors.forEach((v) => {
    if (v.leaderId) {
      if (v.role === 'SELLER') {
        byLeader[v.leaderId] = byLeader[v.leaderId] || [];
        byLeader[v.leaderId].push(v.id);
      } else if (v.role === 'SUBSELLER') {
        // Los subvendedores también se agregan al líder para mostrar en la jerarquía
        byLeader[v.leaderId] = byLeader[v.leaderId] || [];
        byLeader[v.leaderId].push(v.id);
        
        // También los agregamos a su vendedor padre si existe
        // Esto requeriría una lógica más compleja para determinar el vendedor padre específico
      }
    }
  });

  let result = Array.from(vendors.values()).map((v) => ({
    ...v, // Incluir todos los campos del vendedor (incluyendo sellerId)
    ...(stats[v.id] ?? ensure(v.id)),
    children: byLeader[v.id] || [],
  }));

  if (leaderFilter) {
    result = result.filter((v) => v.vendorId === leaderFilter || v.leaderId === leaderFilter);
  }

  res.json({ vendors: result });
});

// POST /reports/clear-commissions - ELIMINA TODOS LOS DATOS DE SALES Y BALANCES
router.post('/clear-commissions', async (req: any, res: any) => {
  try {
    const { confirm, dryRun = false } = req.body;
    
    // Verificar confirmación para evitar ejecuciones accidentales
    if (confirm !== 'ELIMINAR_DATOS_2024') {
      return res.status(400).json({ 
        error: 'Se requiere confirmación. Envía confirm: "ELIMINAR_DATOS_2024" para proceder.' 
      });
    }

    // 1. Contar TODAS las ventas para eliminar
    const salesSnapshot = await db.collection('sales').get();
    const totalSales = salesSnapshot.size;

    // 2. Contar TODOS los balances para eliminar
    const balancesSnapshot = await db.collection('balances').get();
    const totalBalances = balancesSnapshot.size;

    if (dryRun) {
      return res.json({
        message: 'DRY RUN - Solo simulación de eliminación',
        warning: '⚠️ ESTA OPERACIÓN ELIMINARÁ PERMANENTEMENTE TODOS LOS DATOS',
        summary: {
          salesToDelete: totalSales,
          balancesToDelete: totalBalances,
          totalRecordsToDelete: totalSales + totalBalances,
          timestamp: Date.now()
        }
      });
    }

    // ⚠️ EJECUCIÓN REAL - ELIMINAR TODOS LOS DATOS
    // Implementar chunking para evitar límite de 500 operaciones por batch
    const BATCH_SIZE = 500;
    let salesDeleted = 0;
    let balancesDeleted = 0;

    // Eliminar ventas en chunks
    const salesDocs = salesSnapshot.docs;
    for (let i = 0; i < salesDocs.length; i += BATCH_SIZE) {
      const batch = db.batch();
      const chunk = salesDocs.slice(i, i + BATCH_SIZE);
      chunk.forEach((doc) => {
        batch.delete(doc.ref);
        salesDeleted++;
      });
      await batch.commit();
    }

    // Eliminar balances en chunks
    const balancesDocs = balancesSnapshot.docs;
    for (let i = 0; i < balancesDocs.length; i += BATCH_SIZE) {
      const batch = db.batch();
      const chunk = balancesDocs.slice(i, i + BATCH_SIZE);
      chunk.forEach((doc) => {
        batch.delete(doc.ref);
        balancesDeleted++;
      });
      await batch.commit();
    }

    return res.json({
      message: 'TODOS LOS DATOS ELIMINADOS EXITOSAMENTE',
      warning: '⚠️ Esta operación es IRREVERSIBLE',
      summary: {
        salesDeleted,
        balancesDeleted,
        totalRecordsDeleted: salesDeleted + balancesDeleted,
        timestamp: Date.now()
      }
    });

  } catch (error: any) {
    return res.status(500).json({ 
      error: 'Error interno del servidor al eliminar datos',
      details: error.message 
    });
  }
});

export default router; 