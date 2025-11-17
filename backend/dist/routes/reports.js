"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.router = void 0;
const express_1 = require("express");
const index_1 = require("../index");
exports.router = (0, express_1.Router)();
// GET /reports/vendors-summary
exports.router.get('/vendors-summary', async (req, res) => {
    const from = req.query.from ? Number(req.query.from) : undefined;
    const to = req.query.to ? Number(req.query.to) : undefined;
    const leaderFilter = req.query.leaderId;
    // Load vendors
    const vendorSnaps = await index_1.db.collection('vendors').get();
    const vendors = new Map();
    vendorSnaps.docs.forEach((d) => vendors.set(d.id, { id: d.id, ...d.data() }));
    // Prepare stats
    const stats = {};
    const ensure = (id) => (stats[id] ??= {
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
    let q = index_1.db.collection('sales');
    if (from)
        q = q.where('createdAt', '>=', from);
    if (to)
        q = q.where('createdAt', '<=', to);
    const salesSnaps = await q.get();
    salesSnaps.docs.forEach((s) => {
        const sale = s.data();
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
    const byLeader = {};
    vendors.forEach((v) => {
        if (v.leaderId) {
            if (v.role === 'SELLER') {
                byLeader[v.leaderId] = byLeader[v.leaderId] || [];
                byLeader[v.leaderId].push(v.id);
            }
            else if (v.role === 'SUBSELLER') {
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
exports.router.post('/clear-commissions', async (req, res) => {
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
        const salesSnapshot = await index_1.db.collection('sales').get();
        const totalSales = salesSnapshot.size;
        // 2. Contar TODOS los balances para eliminar
        const balancesSnapshot = await index_1.db.collection('balances').get();
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
        const batch = index_1.db.batch();
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
    }
    catch (error) {
        console.error('Error al eliminar datos:', error);
        return res.status(500).json({
            error: 'Error interno del servidor al eliminar datos',
            details: error.message
        });
    }
});
exports.default = exports.router;
