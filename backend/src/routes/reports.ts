import { Router } from 'express';
import { db } from '../index';

export const router = Router();

// GET /reports/vendors-summary
router.get('/vendors-summary', async (req: any, res: any) => {
  const from = req.query.from ? Number(req.query.from) : undefined;
  const to = req.query.to ? Number(req.query.to) : undefined;
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
  });

  // Attach children (sellers under leaders)
  const byLeader: Record<string, string[]> = {};
  vendors.forEach((v) => {
    if (v.leaderId) {
      byLeader[v.leaderId] = byLeader[v.leaderId] || [];
      byLeader[v.leaderId].push(v.id);
    }
  });

  let result = Array.from(vendors.values()).map((v) => ({
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

    console.log(`Iniciando ELIMINACIÓN COMPLETA de datos. Modo dry run: ${dryRun}`);

    // 1. Contar TODAS las ventas para eliminar
    const salesSnapshot = await db.collection('sales').get();
    const totalSales = salesSnapshot.size;

    // 2. Contar TODOS los balances para eliminar
    const balancesSnapshot = await db.collection('balances').get();
    const totalBalances = balancesSnapshot.size;

    console.log(`Encontrados ${totalSales} ventas y ${totalBalances} balances para ELIMINAR COMPLETAMENTE`);

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
    console.log('🚨 INICIANDO ELIMINACIÓN PERMANENTE DE TODOS LOS DATOS...');
    
    const batch = db.batch();
    let salesDeleted = 0;
    let balancesDeleted = 0;

    // Eliminar TODAS las ventas
    salesSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      salesDeleted++;
    });

    // Eliminar TODOS los balances
    balancesSnapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
      balancesDeleted++;
    });

    // Ejecutar batch de eliminación
    await batch.commit();

    console.log('✅ ELIMINACIÓN COMPLETA DE DATOS COMPLETADA EXITOSAMENTE');

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
    console.error('Error al eliminar datos:', error);
    return res.status(500).json({ 
      error: 'Error interno del servidor al eliminar datos',
      details: error.message 
    });
  }
});

export default router; 