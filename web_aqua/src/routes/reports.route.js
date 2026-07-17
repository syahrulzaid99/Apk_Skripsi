const express = require('express');
const router = express.Router();
const { db } = require('../firebaseAdmin');
const { requireAuth, requireRole } = require('../middleware/auth');

// ====================== ADMIN: SALES REPORT PAGE ======================
router.get('/admin/sales-report', requireAuth, requireRole(['admin']), async (req, res) => {
    try {
        // Get all sales
        const snap = await db.collection('sales').orderBy('createdAt', 'desc').get();
        const allSales = snap.docs.map(d => d.data());

        // Get all cabang users
        const cabangSnap = await db.collection('users').where('role', '==', 'cabang').get();
        const cabangMap = {};
        cabangSnap.docs.forEach(d => {
            const u = d.data();
            cabangMap[d.id] = {
                id: d.id,
                username: u.username || d.id,
                nama_cabang: u.nama_cabang || '',
                kota: u.kota || '',
                provinsi: u.provinsi || '',
            };
        });

        // Group by cabang
        const branchMap = {};
        for (const s of allSales) {
            const cid = s.cabang_id;
            if (!cid) continue;
            if (!branchMap[cid]) {
                const info = cabangMap[cid] || {};
                branchMap[cid] = {
                    cabang_id: cid,
                    username: info.username || cid,
                    nama_cabang: info.nama_cabang || '',
                    kota: info.kota || '',
                    provinsi: info.provinsi || '',
                    totalPendapatan: 0,
                    totalTransaksi: 0,
                    totalItemTerjual: 0,
                    monthly: {},
                    recentSales: [],
                };
            }
            const branch = branchMap[cid];
            const total = Number(s.total_harga || s.total_bayar || 0);
            branch.totalPendapatan += total;
            branch.totalTransaksi += 1;

            const items = Array.isArray(s.items) ? s.items : [];
            let itemCount = 0;
            for (const it of items) {
                itemCount += Number(it.qty || 0);
            }
            branch.totalItemTerjual += itemCount;

            // Monthly breakdown
            const createdAt = s.createdAt;
            if (createdAt) {
                let date;
                if (createdAt.toDate) date = createdAt.toDate();
                else if (createdAt._seconds) date = new Date(createdAt._seconds * 1000);
                else date = new Date(createdAt);

                const key = date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0');
                if (!branch.monthly[key]) branch.monthly[key] = { month: key, total: 0, count: 0 };
                branch.monthly[key].total += total;
                branch.monthly[key].count += 1;
            }

            // Keep recent 5 sales per branch
            if (branch.recentSales.length < 5) {
                branch.recentSales.push({
                    kode_penjualan: s.kode_penjualan || '-',
                    total_harga: total,
                    jumlah_item: itemCount,
                    createdAt: createdAt,
                });
            }
        }

        // Convert monthly maps to sorted arrays
        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        const branches = Object.values(branchMap).map(b => {
            const monthlyArr = Object.values(b.monthly)
                .sort((a, c) => a.month.localeCompare(c.month))
                .map(m => {
                    const [y, mo] = m.month.split('-');
                    return { ...m, label: monthNames[parseInt(mo) - 1] + ' ' + y };
                });
            return { ...b, monthly: monthlyArr };
        });

        // Sort by total revenue descending
        branches.sort((a, c) => c.totalPendapatan - a.totalPendapatan);

        // Grand totals
        let grandTotalPendapatan = 0, grandTotalTransaksi = 0, grandTotalItem = 0;
        for (const b of branches) {
            grandTotalPendapatan += b.totalPendapatan;
            grandTotalTransaksi += b.totalTransaksi;
            grandTotalItem += b.totalItemTerjual;
        }

        res.render('admin/sales-report', {
            title: 'Laporan Penjualan per Cabang',
            user: req.user,
            profile: req.profile,
            branches,
            summary: {
                totalCabang: branches.length,
                totalPendapatan: grandTotalPendapatan,
                totalTransaksi: grandTotalTransaksi,
                totalItemTerjual: grandTotalItem,
            },
        });
    } catch (e) {
        console.error('Sales report error:', e);
        res.status(500).send('Error generating sales report');
    }
});

router.get('/admin/reports', requireAuth, requireRole(['admin']), async (req, res) => {
    try {
        const snap = await db.collection('shipments').orderBy('kode_pengiriman').get();
        const shipments = snap.docs.map(d => d.data());

        // Get Users for customer mapping
        const semuaUserIds = [...new Set([
            ...shipments.map(s => s.pengirim).filter(Boolean),
            ...shipments.map(s => s.penerima).filter(Boolean),
        ])];

        const usersMap = {};
        if (semuaUserIds.length > 0) {
            const chunks = []; 
            for (let i = 0; i < semuaUserIds.length; i += 10) chunks.push(semuaUserIds.slice(i, i + 10));
            for (const chunk of chunks) {
                const snaps = await Promise.all(chunk.map(id => db.collection('users').doc(id).get()));
                for (const s of snaps) if (s.exists) usersMap[s.id] = s.data();
            }
        }

        // Flatten data into individual item rows for the report
        const reportRows = [];
        for (const s of shipments) {
            const penerimaUser = usersMap[s.penerima] || {};
            const invDate = s.createdAt && s.createdAt.toDate ? s.createdAt.toDate() : (new Date());
            const items = Array.isArray(s.data_barang) ? s.data_barang : [];
            
            for (const it of items) {
                const qty = Number(it.qty || it.jumlah || it._qty || 0);
                
                reportRows.push({
                    invoice_no: s.kode_pengiriman || '',
                    invoice_date: invDate,
                    delivery_note: s.kode_pengiriman || '',
                    customer_code: s.penerima || '',
                    customer_name: penerimaUser.username || penerimaUser.nama_cabang || penerimaUser.nama || s.penerima || '',
                    po_number: s.po_number || '',
                    so_number: s.so_number || '',
                    po_date: invDate, // Usually same as invoice date if we don't have separate field
                    material_no: it.sku || it.barcode || it.product_id || '',
                    material_desc: it.nama_produk || '',
                    material_div: it.divisi || '',
                    billed_qty: qty,
                    item_net_value: Number(it.item_net_value || 0),
                    item_cost: Number(it.item_cost || 0),
                    item_tax: Number(it.item_tax || 0)
                });
            }
        }

        res.render('admin/reports', {
            title: 'Laporan Penjualan',
            user: req.user, 
            profile: req.profile,
            reportRows
        });
    } catch (e) {
        console.error(e);
        res.status(500).send('Error generating report');
    }
});

// ====================== ADMIN: COMBINED REPORT PAGE ======================
router.get('/admin/laporan', requireAuth, requireRole(['admin']), async (req, res) => {
    try {
        // Fetch sales, orders, and shipments in parallel
        const [salesSnap, ordersSnap, shipmentsSnap, cabangSnap] = await Promise.all([
            db.collection('sales').orderBy('createdAt', 'desc').get(),
            db.collection('orders').orderBy('createdAt', 'desc').get(),
            db.collection('shipments').orderBy('kode_pengiriman').get(),
            db.collection('users').where('role', '==', 'cabang').get(),
        ]);

        const posSales = salesSnap.docs.map(d => d.data());
        const allOrders = ordersSnap.docs.map(d => d.data());

        // Merge: POS sales + orders into unified transactions per cabang
        const allSales = [];
        for (const s of posSales) {
            allSales.push({
                cabang_id: s.cabang_id,
                kode: s.kode_penjualan || '-',
                total: Number(s.total_harga || s.total_bayar || 0),
                items: s.items || [],
                createdAt: s.createdAt,
                source: 'pos',
            });
        }
        for (const o of allOrders) {
            // Only include completed/approved orders
            const st = (o.status || '').toLowerCase();
            if (['approved_admin', 'dipaket', 'dikirim', 'selesai', 'diterima'].includes(st)) {
                allSales.push({
                    cabang_id: o.cabang_id,
                    kode: o.kode_order || '-',
                    total: Number(o.total_harga || 0),
                    items: o.items || [],
                    createdAt: o.createdAt,
                    source: 'order',
                });
            }
        }
        const shipments = shipmentsSnap.docs.map(d => d.data());

        // Build cabang map
        const cabangMap = {};
        cabangSnap.docs.forEach(d => {
            const u = d.data();
            cabangMap[d.id] = {
                id: d.id,
                username: u.username || d.id,
                nama_cabang: u.nama_cabang || '',
                kota: u.kota || '',
                provinsi: u.provinsi || '',
            };
        });

        // ── Sales data (merged POS + Orders) ──
        const branchMap = {};
        for (const s of allSales) {
            const cid = s.cabang_id;
            if (!cid) continue;
            if (!branchMap[cid]) {
                const info = cabangMap[cid] || {};
                branchMap[cid] = {
                    cabang_id: cid,
                    username: info.username || cid,
                    nama_cabang: info.nama_cabang || '',
                    kota: info.kota || '',
                    provinsi: info.provinsi || '',
                    totalPendapatan: 0,
                    totalTransaksi: 0,
                    totalItemTerjual: 0,
                    monthly: {},
                    recentSales: [],
                };
            }
            const branch = branchMap[cid];
            branch.totalPendapatan += s.total;
            branch.totalTransaksi += 1;

            const items = Array.isArray(s.items) ? s.items : [];
            let itemCount = 0;
            for (const it of items) itemCount += Number(it.qty || 0);
            branch.totalItemTerjual += itemCount;

            const createdAt = s.createdAt;
            if (createdAt) {
                let date;
                if (createdAt.toDate) date = createdAt.toDate();
                else if (createdAt._seconds) date = new Date(createdAt._seconds * 1000);
                else date = new Date(createdAt);
                const key = date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0');
                if (!branch.monthly[key]) branch.monthly[key] = { month: key, total: 0, count: 0 };
                branch.monthly[key].total += s.total;
                branch.monthly[key].count += 1;
            }

            if (branch.recentSales.length < 5) {
                branch.recentSales.push({
                    kode_penjualan: s.kode,
                    total_harga: s.total,
                    jumlah_item: itemCount,
                    createdAt: createdAt,
                    source: s.source,
                });
            }
        }

        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        const branches = Object.values(branchMap).map(b => {
            const monthlyArr = Object.values(b.monthly)
                .sort((a, c) => a.month.localeCompare(c.month))
                .map(m => {
                    const [y, mo] = m.month.split('-');
                    return { ...m, label: monthNames[parseInt(mo) - 1] + ' ' + y };
                });
            return { ...b, monthly: monthlyArr };
        }).sort((a, c) => c.totalPendapatan - a.totalPendapatan);

        let grandTotalPendapatan = 0, grandTotalTransaksi = 0, grandTotalItem = 0;
        for (const b of branches) {
            grandTotalPendapatan += b.totalPendapatan;
            grandTotalTransaksi += b.totalTransaksi;
            grandTotalItem += b.totalItemTerjual;
        }

        // ── Shipment data ──
        const semuaUserIds = [...new Set([
            ...shipments.map(s => s.pengirim).filter(Boolean),
            ...shipments.map(s => s.penerima).filter(Boolean),
        ])];

        const usersMap = {};
        if (semuaUserIds.length > 0) {
            const chunks = [];
            for (let i = 0; i < semuaUserIds.length; i += 10) chunks.push(semuaUserIds.slice(i, i + 10));
            for (const chunk of chunks) {
                const snaps = await Promise.all(chunk.map(id => db.collection('users').doc(id).get()));
                for (const s of snaps) if (s.exists) usersMap[s.id] = s.data();
            }
        }

        const reportRows = [];
        for (const s of shipments) {
            const penerimaUser = usersMap[s.penerima] || {};
            const invDate = s.createdAt && s.createdAt.toDate ? s.createdAt.toDate() : (new Date());
            const items = Array.isArray(s.data_barang) ? s.data_barang : [];

            for (const it of items) {
                const qty = Number(it.qty || it.jumlah || it._qty || 0);
                reportRows.push({
                    invoice_no: s.kode_pengiriman || '',
                    invoice_date: invDate,
                    delivery_note: s.kode_pengiriman || '',
                    customer_code: s.penerima || '',
                    customer_name: penerimaUser.username || penerimaUser.nama_cabang || penerimaUser.nama || s.penerima || '',
                    po_number: s.po_number || '',
                    so_number: s.so_number || '',
                    po_date: invDate,
                    material_no: it.sku || it.barcode || it.product_id || '',
                    material_desc: it.nama_produk || '',
                    material_div: it.divisi || '',
                    billed_qty: qty,
                    item_net_value: Number(it.item_net_value || 0),
                    item_cost: Number(it.item_cost || 0),
                    item_tax: Number(it.item_tax || 0),
                });
            }
        }

        res.render('admin/laporan', {
            title: 'Laporan',
            user: req.user,
            profile: req.profile,
            branches,
            salesSummary: {
                totalCabang: branches.length,
                totalPendapatan: grandTotalPendapatan,
                totalTransaksi: grandTotalTransaksi,
                totalItemTerjual: grandTotalItem,
            },
            reportRows,
        });
    } catch (e) {
        console.error('Combined report error:', e);
        res.status(500).send('Error generating report');
    }
});

module.exports = router;
