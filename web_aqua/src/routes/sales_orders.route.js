const express = require('express');
const router = express.Router();
const { csrfProtection } = require('../middleware/csrf');
const admin = require('firebase-admin');

const { db } = require('../firebaseAdmin');
const { requireAuth, requireRole, requireAuthApi } = require('../middleware/auth');
const { snap } = require('../midtransClient');

router.use(express.urlencoded({ extended: false }));

// Helper to get users map
async function getUsersMapByIds(ids = []) {
    if (!ids.length) return {};
    const chunks = [];
    for (let i = 0; i < ids.length; i += 10) chunks.push(ids.slice(i, i + 10));
    const map = {};
    for (const chunk of chunks) {
        const snaps = await Promise.all(chunk.map(id => db.collection('users').doc(id).get()));
        for (const s of snaps) if (s.exists) map[s.id] = s.data();
    }
    return map;
}

// ====================== SALES: LIST ORDERS (yang dibuat sales) ======================
router.get('/sales/orders', requireAuth, requireRole(['sales']), csrfProtection, async (req, res) => {
    try {
        const snap = await db.collection('orders').orderBy('createdAt', 'desc').get();
        const allOrders = snap.docs.map(d => d.data());

        // Sales lihat SEMUA order (bantu cabang) + bisa buat order baru
        const cabangIds = [...new Set(allOrders.map(o => o.cabang_id).filter(Boolean))];
        const usersMap = await getUsersMapByIds(cabangIds);

        const cabangUsers = await db.collection('users').where('role', '==', 'cabang').get();
        const cabangList = cabangUsers.docs.map(d => ({ id: d.id, username: d.data().username || d.id }));

        res.render('sales/orders', {
            title: 'Pesanan',
            csrfToken: req.csrfToken(),
            user: req.user,
            profile: req.profile,
            orders: allOrders,
            usersMap,
            cabangList,
            ok: req.query.ok || null,
            err: req.query.err || null,
        });
    } catch (error) {
        console.error("Error loading sales orders:", error);
        const cabangUsers = await db.collection('users').where('role', '==', 'cabang').get();
        const cabangList = cabangUsers.docs.map(d => ({ id: d.id, username: d.data().username || d.id }));
        res.render('sales/orders', {
            title: 'Pesanan',
            csrfToken: req.csrfToken(),
            user: req.user,
            profile: req.profile,
            orders: [],
            usersMap: {},
            cabangList,
            ok: req.query.ok || null,
            err: "Gagal memuat daftar pesanan.",
        });
    }
});

// ====================== SALES: APPROVE ORDER (konfirmasi ke admin) ======================
router.post('/sales/orders/:id/approve', requireAuth, requireRole(['sales']), csrfProtection, async (req, res) => {
    try {
        const id = req.params.id;
        const ref = db.collection('orders').doc(id);
        const cur = await ref.get();

        if (!cur.exists) {
            return res.redirect('/sales/orders?err=' + encodeURIComponent('Pesanan tidak ditemukan'));
        }

        const currentData = cur.data();
        const curStatus = (currentData.status || '').toLowerCase();
        const paymentStatus = (currentData.payment_status || '').toLowerCase();

        if (curStatus !== 'pending') {
            return res.redirect('/sales/orders?err=' + encodeURIComponent('Pesanan harus berstatus menunggu'));
        }
        if (paymentStatus !== 'settlement' && paymentStatus !== 'capture') {
            return res.redirect('/sales/orders?err=' + encodeURIComponent('Pesanan belum dibayar oleh cabang'));
        }

        const keterangan = typeof req.body.keterangan === 'string' ? req.body.keterangan.trim() : '';

        const history = Array.isArray(currentData.history) ? currentData.history : [];
        history.push({
            status: 'approved_sales',
            by: req.user.uid,
            by_username: req.user.username,
            at: new Date(),
            note: keterangan,
        });

        await ref.update({
            status: 'approved_sales',
            approved_sales_at: new Date(),
            approved_sales_by: req.user.uid,
            keterangan_sales: keterangan,
            history,
            updatedAt: new Date()
        });

        console.log(`[Sales] Order ${currentData.kode_order || id} dikonfirmasi oleh ${req.user.username} -> menunggu verifikasi admin`);
        return res.redirect('/sales/orders?ok=approved');
    } catch (e) {
        console.error(e);
        return res.redirect('/sales/orders?err=' + encodeURIComponent('Gagal konfirmasi pesanan'));
    }
});

// ====================== SALES: REJECT ORDER ======================
router.post('/sales/orders/:id/reject', requireAuth, requireRole(['sales']), csrfProtection, async (req, res) => {
    try {
        const id = req.params.id;
        const ref = db.collection('orders').doc(id);
        const cur = await ref.get();

        if (!cur.exists) {
            return res.redirect('/sales/orders?err=' + encodeURIComponent('Pesanan tidak ditemukan'));
        }

        const currentData = cur.data();
        if ((currentData.status || '').toLowerCase() !== 'pending') {
            return res.redirect('/sales/orders?err=' + encodeURIComponent('Pesanan harus berstatus menunggu'));
        }

        const alasan = typeof req.body.alasan === 'string' ? req.body.alasan.trim() : '';
        if (!alasan) {
            return res.redirect('/sales/orders?err=' + encodeURIComponent('Alasan penolakan wajib diisi'));
        }

        const history = Array.isArray(currentData.history) ? currentData.history : [];
        history.push({
            status: 'rejected',
            by: req.user.uid,
            by_username: req.user.username,
            at: new Date(),
            note: alasan,
        });

        await ref.update({
            status: 'rejected',
            rejected_at: new Date(),
            rejected_by: req.user.uid,
            rejection_reason: alasan,
            history,
            updatedAt: new Date()
        });

        // Kembalikan stok pusat karena pesanan dibatalkan
        const items = Array.isArray(currentData.items) ? currentData.items : [];
        const batch = db.batch();
        let hasOp = false;
        for (const item of items) {
            const qty = Number(item.qty || 0);
            if (item.product_id && qty > 0) {
                batch.update(db.collection('products').doc(item.product_id), {
                    stok: admin.firestore.FieldValue.increment(qty),
                    updatedAt: new Date()
                });
                hasOp = true;
            }
        }
        if (hasOp) await batch.commit().catch(e => console.error('Failed to restore stock on reject:', e));

        console.log(`[Sales] Order ${currentData.kode_order || id} ditolak oleh ${req.user.username}`);
        return res.redirect('/sales/orders?ok=rejected');
    } catch (e) {
        console.error(e);
        return res.redirect('/sales/orders?err=' + encodeURIComponent('Gagal menolak pesanan'));
    }
});

// ====================== SALES: HISTORY APPROVAL (WEB) ======================
router.get('/sales/history', requireAuth, requireRole(['sales']), csrfProtection, async (req, res) => {
    try {
        const snap = await db.collection('orders').orderBy('createdAt', 'desc').get();
        const all = snap.docs.map(d => d.data());

        // Keputusan yang diambil sales yang sedang login.
        // Diputuskan lewat field SIAPA yang mengambil keputusan (bukan status saat ini),
        // karena setelah disetujui status bisa lanjut ke approved_admin/dipaket/dikirim/diterima
        // atau diubah admin menjadi ditolak — riwayat sales harus tetap mencatat keputusannya.
        const orders = all.filter(o => {
            if (o.approved_sales_by === req.user.uid) return true;
            if (o.rejected_by === req.user.uid) return true;
            return false;
        });

        const cabangIds = [...new Set(orders.map(o => o.cabang_id).filter(Boolean))];
        const usersMap = await getUsersMapByIds(cabangIds);

        res.render('sales/history', {
            title: 'Riwayat Approval',
            csrfToken: req.csrfToken(),
            user: req.user,
            profile: req.profile,
            orders,
            usersMap,
        });
    } catch (e) {
        console.error('[Sales] History error:', e);
        res.render('sales/history', {
            title: 'Riwayat Approval',
            csrfToken: req.csrfToken(),
            user: req.user,
            profile: req.profile,
            orders: [],
            usersMap: {},
        });
    }
});

// ====================== SALES: TRACKING PENGIRIMAN (WEB) ======================
router.get('/sales/tracking', requireAuth, requireRole(['sales']), csrfProtection, async (req, res) => {
    try {
        const snap = await db.collection('orders').orderBy('createdAt', 'desc').get();
        const all = snap.docs.map(d => d.data());

        // Map shipment untuk info resi & waktu diterima
        const shipmentIds = [...new Set(all.map(o => o.shipment_id).filter(Boolean))];
        const shipMap = {};
        for (let i = 0; i < shipmentIds.length; i += 10) {
            const chunk = shipmentIds.slice(i, i + 10);
            const snaps = await Promise.all(chunk.map(id => db.collection('shipments').doc(id).get()));
            for (const s of snaps) if (s.exists) shipMap[s.id] = s.data();
        }

        const cabangIds = [...new Set(all.map(o => o.cabang_id).filter(Boolean))];
        const usersMap = await getUsersMapByIds(cabangIds);

        res.render('sales/tracking', {
            title: 'Tracking Pengiriman',
            csrfToken: req.csrfToken(),
            user: req.user,
            profile: req.profile,
            orders: all,
            usersMap,
            shipMap,
        });
    } catch (e) {
        console.error('[Sales] Tracking error:', e);
        res.render('sales/tracking', {
            title: 'Tracking Pengiriman',
            csrfToken: req.csrfToken(),
            user: req.user,
            profile: req.profile,
            orders: [],
            usersMap: {},
            shipMap: {},
        });
    }
});

// ====================== SALES: API for Flutter ======================

// GET orders for flutter
router.get('/api/v1/sales/orders', requireAuthApi, requireRole(['sales']), async (req, res) => {
    try {
        const snap = await db.collection('orders').orderBy('createdAt', 'desc').get();
        const allOrders = snap.docs.map(d => d.data());

        const cabangIds = [...new Set(allOrders.map(o => o.cabang_id).filter(Boolean))];
        const usersMap = await getUsersMapByIds(cabangIds);

        const result = allOrders.map(o => ({
            id: o.id,
            kode_order: o.kode_order,
            cabang_id: o.cabang_id,
            cabang_username: o.cabang_username || usersMap[o.cabang_id]?.username || o.cabang_id,
            cabang_nama: usersMap[o.cabang_id]?.nama_cabang || '',
            status: o.status || 'pending',
            payment_status: o.payment_status || 'pending',
            total_harga: o.total_harga || 0,
            jumlah_item: Array.isArray(o.items) ? o.items.length : 0,
            items: o.items || [],
            keterangan: o.keterangan || '',
            created_by_role: o.created_by_role || '',
            createdAt: o.createdAt || null,
        }));

        return res.json({ orders: result });
    } catch (e) {
        console.error(e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== SALES: TRACKING PENGIRIMAN (API Flutter) ======================
router.get('/api/v1/sales/tracking', requireAuthApi, requireRole(['sales']), async (req, res) => {
    try {
        const snap = await db.collection('orders').orderBy('createdAt', 'desc').get();
        const all = snap.docs.map(d => ({ id: d.id, ...d.data() }));

        // Map shipment untuk resi & waktu diterima
        const shipmentIds = [...new Set(all.map(o => o.shipment_id).filter(Boolean))];
        const shipMap = {};
        for (let i = 0; i < shipmentIds.length; i += 10) {
            const chunk = shipmentIds.slice(i, i + 10);
            const snaps = await Promise.all(chunk.map(id => db.collection('shipments').doc(id).get()));
            for (const s of snaps) if (s.exists) shipMap[s.id] = s.data();
        }

        const cabangIds = [...new Set(all.map(o => o.cabang_id).filter(Boolean))];
        const usersMap = await getUsersMapByIds(cabangIds);

        const result = all.map(o => {
            const items = Array.isArray(o.items) ? o.items : [];
            return {
                id: o.id,
                kode_order: o.kode_order,
                cabang_id: o.cabang_id,
                cabang_username: o.cabang_username || usersMap[o.cabang_id]?.username || o.cabang_id,
                cabang_nama: usersMap[o.cabang_id]?.nama_cabang || '',
                status: o.status || 'pending',
                payment_status: o.payment_status || 'pending',
                total_harga: o.total_harga || 0,
                jumlah_item: items.length,
                items: items.map(it => ({
                    nama_produk: it.nama_produk || it.nama || it.product_name || 'Produk',
                    qty: Number(it.qty || 0),
                    harga: it.harga || it.price || 0,
                })),
                keterangan_sales: o.keterangan_sales || '',
                rejection_reason: o.rejection_reason || '',
                kode_pengiriman: o.kode_pengiriman || '',
                shipment_id: o.shipment_id || '',
                createdAt: o.createdAt || null,
                approved_sales_at: o.approved_sales_at || null,
                approved_admin_at: o.approved_admin_at || null,
                packed_at: o.packed_at || null,
                rejected_at: o.rejected_at || null,
                dikirim_at: shipMap[o.shipment_id]?.createdAt || null,
                diterima_at: shipMap[o.shipment_id]?.diterima_at || null,
                diterima_oleh: shipMap[o.shipment_id]?.diterima_oleh || '',
                history: (Array.isArray(o.history) ? o.history : []).map(h => ({
                    status: h.status || '',
                    by_username: h.by_username || h.by || '',
                    at: h.at || null,
                    note: h.note || '',
                })),
            };
        });

        return res.json({ orders: result });
    } catch (e) {
        console.error('[Sales] Tracking API error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== SALES: RETRY PAYMENT ======================
router.post('/api/v1/sales/orders/:id/pay', requireAuthApi, requireRole(['sales']), async (req, res) => {
    try {
        const id = req.params.id;
        const docRef = db.collection('orders').doc(id);
        const docSnap = await docRef.get();

        if (!docSnap.exists) {
            return res.status(404).json({ error: 'not_found' });
        }

        const docData = docSnap.data();

        // Sales boleh bayar order yang dia buat atau yang untuk cabangnya
        if (docData.created_by !== req.user.uid) {
            return res.status(403).json({ error: 'forbidden' });
        }

        if (docData.status !== 'pending') {
            return res.status(400).json({ error: 'order_not_pending' });
        }

        const midtrans_order_id = `${docData.kode_order}-${Date.now()}`;
        const grossAmount = Math.round(docData.total_harga || 0);

        const parameter = {
            transaction_details: {
                order_id: midtrans_order_id,
                gross_amount: grossAmount,
            },
            customer_details: {
                first_name: req.user.username || 'Sales',
            },
            enabled_payments: [
                'credit_card', 'bca_va', 'bni_va', 'bri_va',
                'permata_va', 'mandiri_bill',
                'gopay', 'shopeepay', 'other_qris',
                'alfamart', 'indomaret',
            ],
        };

        console.log('[Midtrans] Sales retry:', midtrans_order_id, 'amount:', grossAmount);

        let transaction;
        try {
            transaction = await snap.createTransaction(parameter);
        } catch (midErr) {
            console.error('[Midtrans] GAGAL:', midErr?.message || midErr);
            return res.status(502).json({ error: 'midtrans_failed' });
        }

        await docRef.update({
            midtrans_order_id,
            snap_token: transaction.token,
            payment_url: transaction.redirect_url,
            payment_status: 'pending',
            updatedAt: new Date(),
        });

        return res.json({ ok: true, payment_url: transaction.redirect_url });
    } catch (e) {
        console.error('❌ Sales pay error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== SALES: APPROVE/REJECT ORDER (API untuk Flutter) ======================
router.post('/api/v1/sales/orders/:id/approve', requireAuthApi, requireRole(['sales']), express.json(), async (req, res) => {
    try {
        const id = req.params.id;
        const ref = db.collection('orders').doc(id);
        const cur = await ref.get();

        if (!cur.exists) return res.status(404).json({ error: 'not_found' });

        const currentData = cur.data();
        const curStatus = (currentData.status || '').toLowerCase();
        const paymentStatus = (currentData.payment_status || '').toLowerCase();

        if (curStatus !== 'pending') return res.status(400).json({ error: 'not_pending' });
        if (paymentStatus !== 'settlement' && paymentStatus !== 'capture') {
            return res.status(400).json({ error: 'not_paid' });
        }

        const keterangan = typeof req.body?.keterangan === 'string' ? req.body.keterangan.trim() : '';

        const history = Array.isArray(currentData.history) ? currentData.history : [];
        history.push({
            status: 'approved_sales',
            by: req.user.uid,
            by_username: req.user.username,
            at: new Date(),
            note: keterangan,
        });

        await ref.update({
            status: 'approved_sales',
            approved_sales_at: new Date(),
            approved_sales_by: req.user.uid,
            keterangan_sales: keterangan,
            history,
            updatedAt: new Date()
        });

        return res.json({ ok: true, status: 'approved_sales' });
    } catch (e) {
        console.error('[Sales API] Approve error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

router.post('/api/v1/sales/orders/:id/reject', requireAuthApi, requireRole(['sales']), express.json(), async (req, res) => {
    try {
        const id = req.params.id;
        const ref = db.collection('orders').doc(id);
        const cur = await ref.get();

        if (!cur.exists) return res.status(404).json({ error: 'not_found' });

        const currentData = cur.data();
        if ((currentData.status || '').toLowerCase() !== 'pending') {
            return res.status(400).json({ error: 'not_pending' });
        }

        const alasan = typeof req.body?.alasan === 'string' ? req.body.alasan.trim() : '';
        if (!alasan) return res.status(400).json({ error: 'reason_required' });

        const history = Array.isArray(currentData.history) ? currentData.history : [];
        history.push({
            status: 'rejected',
            by: req.user.uid,
            by_username: req.user.username,
            at: new Date(),
            note: alasan,
        });

        await ref.update({
            status: 'rejected',
            rejected_at: new Date(),
            rejected_by: req.user.uid,
            rejection_reason: alasan,
            history,
            updatedAt: new Date()
        });

        // Kembalikan stok pusat
        const items = Array.isArray(currentData.items) ? currentData.items : [];
        const batch = db.batch();
        let hasOp = false;
        for (const item of items) {
            const qty = Number(item.qty || 0);
            if (item.product_id && qty > 0) {
                batch.update(db.collection('products').doc(item.product_id), {
                    stok: admin.firestore.FieldValue.increment(qty),
                    updatedAt: new Date()
                });
                hasOp = true;
            }
        }
        if (hasOp) await batch.commit().catch(e => console.error('Failed to restore stock on reject:', e));

        return res.json({ ok: true, status: 'rejected' });
    } catch (e) {
        console.error('[Sales API] Reject error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== SALES: REPORT PAGE (WEB) ======================
router.get('/sales/report', requireAuth, requireRole(['sales']), csrfProtection, async (req, res) => {
    try {
        const snap = await db.collection('orders')
            .where('created_by', '==', req.user.uid)
            .get();

        const orders = snap.docs.map(d => d.data());

        // sort client-side
        orders.sort((a, b) => {
            const da = a.createdAt ? new Date(a.createdAt._seconds ? a.createdAt._seconds * 1000 : a.createdAt) : new Date(0);
            const db2 = b.createdAt ? new Date(b.createdAt._seconds ? b.createdAt._seconds * 1000 : b.createdAt) : new Date(0);
            return db2 - da;
        });

        // Get cabang names
        const cabangIds = [...new Set(orders.map(o => o.cabang_id).filter(Boolean))];
        const usersMap = await getUsersMapByIds(cabangIds);

        // Summary
        let totalPendapatan = 0, totalItem = 0;
        const statusCount = { pending: 0, approved_sales: 0, approved_admin: 0, dipaket: 0, dikirim: 0, selesai: 0, rejected: 0 };
        const monthlyMap = {};

        for (const o of orders) {
            totalPendapatan += Number(o.total_harga || 0);
            const items = Array.isArray(o.items) ? o.items : [];
            for (const it of items) totalItem += Number(it.qty || 0);

            const st = (o.status || 'pending').toLowerCase();
            if (statusCount[st] !== undefined) statusCount[st]++;
            else if (st === 'diterima') statusCount.selesai++;

            // Monthly
            const createdAt = o.createdAt;
            if (createdAt) {
                let date;
                if (createdAt.toDate) date = createdAt.toDate();
                else if (createdAt._seconds) date = new Date(createdAt._seconds * 1000);
                else date = new Date(createdAt);
                const key = date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0');
                if (!monthlyMap[key]) monthlyMap[key] = { month: key, total: 0, count: 0 };
                monthlyMap[key].total += Number(o.total_harga || 0);
                monthlyMap[key].count += 1;
            }
        }

        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        const monthly = Object.values(monthlyMap)
            .sort((a, c) => a.month.localeCompare(c.month))
            .map(m => {
                const [y, mo] = m.month.split('-');
                return { ...m, label: monthNames[parseInt(mo) - 1] + ' ' + y };
            });

        // Per-cabang breakdown
        const cabangMap = {};
        for (const o of orders) {
            const cid = o.cabang_id || 'unknown';
            if (!cabangMap[cid]) {
                const info = usersMap[cid] || {};
                cabangMap[cid] = {
                    cabang_id: cid,
                    username: info.username || cid,
                    nama_cabang: info.nama_cabang || '',
                    kota: info.kota || '',
                    provinsi: info.provinsi || '',
                    totalPendapatan: 0,
                    totalOrders: 0,
                    totalItem: 0,
                    monthly: {},
                };
            }
            const b = cabangMap[cid];
            b.totalPendapatan += Number(o.total_harga || 0);
            b.totalOrders += 1;
            const items2 = Array.isArray(o.items) ? o.items : [];
            for (const it of items2) b.totalItem += Number(it.qty || 0);

            const createdAt2 = o.createdAt;
            if (createdAt2) {
                let date2;
                if (createdAt2.toDate) date2 = createdAt2.toDate();
                else if (createdAt2._seconds) date2 = new Date(createdAt2._seconds * 1000);
                else date2 = new Date(createdAt2);
                const key2 = date2.getFullYear() + '-' + String(date2.getMonth() + 1).padStart(2, '0');
                if (!b.monthly[key2]) b.monthly[key2] = { month: key2, total: 0, count: 0 };
                b.monthly[key2].total += Number(o.total_harga || 0);
                b.monthly[key2].count += 1;
            }
        }

        const branches = Object.values(cabangMap).map(b => {
            const monthlyArr = Object.values(b.monthly)
                .sort((a, c) => a.month.localeCompare(c.month))
                .map(m => {
                    const [y2, mo2] = m.month.split('-');
                    return { ...m, label: monthNames[parseInt(mo2) - 1] + ' ' + y2 };
                });
            return { ...b, monthly: monthlyArr };
        }).sort((a, c) => c.totalPendapatan - a.totalPendapatan);

        res.render('sales/report', {
            title: 'Laporan Penjualan',
            csrfToken: req.csrfToken(),
            user: req.user,
            profile: req.profile,
            orders,
            usersMap,
            summary: {
                totalOrders: orders.length,
                totalPendapatan,
                totalItem,
            },
            statusCount,
            monthly,
            branches,
        });
    } catch (e) {
        console.error('[Sales] Report error:', e);
        res.status(500).send('Error generating report');
    }
});

// ====================== SALES: REPORT API (FLUTTER) ======================
router.get('/api/v1/sales/report', requireAuthApi, requireRole(['sales']), async (req, res) => {
    try {
        const snap = await db.collection('orders')
            .where('created_by', '==', req.user.uid)
            .get();

        const orders = snap.docs.map(d => d.data());

        // sort client-side
        orders.sort((a, b) => {
            const da = a.createdAt ? new Date(a.createdAt._seconds ? a.createdAt._seconds * 1000 : a.createdAt) : new Date(0);
            const db2 = b.createdAt ? new Date(b.createdAt._seconds ? b.createdAt._seconds * 1000 : b.createdAt) : new Date(0);
            return db2 - da;
        });

        // Get cabang names
        const cabangIds = [...new Set(orders.map(o => o.cabang_id).filter(Boolean))];
        const usersMap = await getUsersMapByIds(cabangIds);

        let totalPendapatan = 0, totalItem = 0;
        const monthlyMap = {};

        for (const o of orders) {
            totalPendapatan += Number(o.total_harga || 0);
            const items = Array.isArray(o.items) ? o.items : [];
            for (const it of items) totalItem += Number(it.qty || 0);

            const createdAt = o.createdAt;
            if (createdAt) {
                let date;
                if (createdAt.toDate) date = createdAt.toDate();
                else if (createdAt._seconds) date = new Date(createdAt._seconds * 1000);
                else date = new Date(createdAt);
                const key = date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0');
                if (!monthlyMap[key]) monthlyMap[key] = { month: key, total: 0, count: 0 };
                monthlyMap[key].total += Number(o.total_harga || 0);
                monthlyMap[key].count += 1;
            }
        }

        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        const monthly = Object.values(monthlyMap)
            .sort((a, c) => a.month.localeCompare(c.month))
            .map(m => {
                const [y, mo] = m.month.split('-');
                return { ...m, label: monthNames[parseInt(mo) - 1] + ' ' + y };
            });

        const recentOrders = orders.slice(0, 50).map(o => ({
            id: o.id,
            kode_order: o.kode_order,
            cabang_username: o.cabang_username || usersMap[o.cabang_id]?.username || o.cabang_id,
            cabang_nama: usersMap[o.cabang_id]?.nama_cabang || '',
            status: o.status || 'pending',
            payment_status: o.payment_status || 'pending',
            total_harga: Number(o.total_harga || 0),
            jumlah_item: Array.isArray(o.items) ? o.items.reduce((s, it) => s + Number(it.qty || 0), 0) : 0,
            createdAt: o.createdAt || null,
        }));

        // Per-cabang breakdown
        const cabangMap = {};
        for (const o of orders) {
            const cid = o.cabang_id || 'unknown';
            if (!cabangMap[cid]) {
                const info = usersMap[cid] || {};
                cabangMap[cid] = {
                    cabang_id: cid,
                    username: info.username || cid,
                    nama_cabang: info.nama_cabang || '',
                    kota: info.kota || '',
                    provinsi: info.provinsi || '',
                    totalPendapatan: 0,
                    totalOrders: 0,
                    totalItem: 0,
                    monthly: {},
                };
            }
            const b = cabangMap[cid];
            b.totalPendapatan += Number(o.total_harga || 0);
            b.totalOrders += 1;
            const items = Array.isArray(o.items) ? o.items : [];
            for (const it of items) b.totalItem += Number(it.qty || 0);

            const createdAt = o.createdAt;
            if (createdAt) {
                let date;
                if (createdAt.toDate) date = createdAt.toDate();
                else if (createdAt._seconds) date = new Date(createdAt._seconds * 1000);
                else date = new Date(createdAt);
                const key = date.getFullYear() + '-' + String(date.getMonth() + 1).padStart(2, '0');
                if (!b.monthly[key]) b.monthly[key] = { month: key, total: 0, count: 0 };
                b.monthly[key].total += Number(o.total_harga || 0);
                b.monthly[key].count += 1;
            }
        }

        const branches = Object.values(cabangMap).map(b => {
            const monthlyArr = Object.values(b.monthly)
                .sort((a, c) => a.month.localeCompare(c.month))
                .map(m => {
                    const [y, mo] = m.month.split('-');
                    return { ...m, label: monthNames[parseInt(mo) - 1] + ' ' + y };
                });
            return { ...b, monthly: monthlyArr };
        }).sort((a, c) => c.totalPendapatan - a.totalPendapatan);

        return res.json({
            summary: {
                totalOrders: orders.length,
                totalPendapatan,
                totalItem,
            },
            monthly,
            branches,
            recentOrders,
        });
    } catch (e) {
        console.error('[Sales] Report API error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

module.exports = router;
