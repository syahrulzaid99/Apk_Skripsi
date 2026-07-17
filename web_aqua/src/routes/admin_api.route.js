const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { randomUUID } = require('crypto');
const admin = require('firebase-admin');
const multer = require('multer');
const path = require('path');

const { db } = require('../firebaseAdmin');
const { requireAuthApi, requireRole } = require('../middleware/auth');
const { uploadToStorage, deleteFromStorage } = require('../storageHelper');

const upload = multer({
    storage: multer.memoryStorage(),
    fileFilter: (req, file, cb) => {
        const ok = /^image\/(png|jpe?g|gif|webp|svg\+xml)$/.test(file.mimetype);
        cb(ok ? null : new Error('File harus gambar'), ok);
    },
    limits: { fileSize: 5 * 1024 * 1024 }
});

// ====================== HELPERS ======================
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

// ====================== ADMIN: DASHBOARD ======================
router.get('/api/v1/admin/dashboard', requireAuthApi, requireRole(['admin']), async (req, res) => {
    try {
        const [ordersSnap, usersSnap, productsSnap, shipmentsSnap] = await Promise.all([
            db.collection('orders').get(),
            db.collection('users').get(),
            db.collection('products').get(),
            db.collection('shipments').get(),
        ]);

        let pending = 0, approved = 0, dipaket = 0, dikirim = 0, diterima = 0;
        ordersSnap.docs.forEach(d => {
            const st = (d.data().status || '').toLowerCase();
            if (st === 'pending') pending++;
            else if (st === 'approved_admin') approved++;
            else if (st === 'dipaket') dipaket++;
            else if (st === 'dikirim') dikirim++;
            else if (st === 'diterima' || st === 'selesai') diterima++;
        });

        let adminCount = 0, cabangCount = 0, salesCount = 0, gudangCount = 0;
        usersSnap.docs.forEach(d => {
            const r = d.data().role;
            if (r === 'admin') adminCount++;
            else if (r === 'cabang') cabangCount++;
            else if (r === 'sales') salesCount++;
            else if (r === 'gudang') gudangCount++;
        });

        let shipDikirim = 0, shipDiterima = 0, shipDitolak = 0;
        shipmentsSnap.docs.forEach(d => {
            const st = (d.data().status || '').toLowerCase();
            if (st === 'dikirim') shipDikirim++;
            else if (st === 'diterima') shipDiterima++;
            else if (st === 'ditolak') shipDitolak++;
        });

        return res.json({
            orders: { pending, approved, dipaket, dikirim, diterima, total: ordersSnap.size },
            users: { admin: adminCount, cabang: cabangCount, sales: salesCount, gudang: gudangCount, total: usersSnap.size },
            products: { total: productsSnap.size },
            shipments: { dikirim: shipDikirim, diterima: shipDiterima, ditolak: shipDitolak, total: shipmentsSnap.size },
        });
    } catch (e) {
        console.error('[Admin API] Dashboard error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== ADMIN: LIST ORDERS ======================
router.get('/api/v1/admin/orders', requireAuthApi, requireRole(['admin']), async (req, res) => {
    try {
        const snap = await db.collection('orders').orderBy('createdAt', 'desc').get();
        const orders = snap.docs.map(d => d.data());

        const cabangIds = [...new Set(orders.map(o => o.cabang_id).filter(Boolean))];
        const usersMap = await getUsersMapByIds(cabangIds);

        const result = orders.map(o => ({
            id: o.id,
            kode_order: o.kode_order,
            cabang_id: o.cabang_id,
            cabang_username: o.cabang_username || usersMap[o.cabang_id]?.username || o.cabang_id,
            cabang_nama: usersMap[o.cabang_id]?.nama_cabang || '',
            cabang_kota: usersMap[o.cabang_id]?.kota || '',
            status: o.status || 'pending',
            payment_status: o.payment_status || 'pending',
            total_harga: o.total_harga || 0,
            jumlah_item: Array.isArray(o.items) ? o.items.length : 0,
            items: o.items || [],
            keterangan: o.keterangan || '',
            keterangan_admin: o.keterangan_admin || '',
            created_by_role: o.created_by_role || '',
            createdAt: o.createdAt || null,
        }));

        return res.json({ orders: result });
    } catch (e) {
        console.error('[Admin API] Orders error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== ADMIN: APPROVE ORDER ======================
router.post('/api/v1/admin/orders/:id/approve', requireAuthApi, requireRole(['admin']), express.json(), async (req, res) => {
    try {
        const id = req.params.id;
        const ref = db.collection('orders').doc(id);
        const cur = await ref.get();

        if (!cur.exists) return res.status(404).json({ error: 'not_found' });

        const currentData = cur.data();
        const curStatus = (currentData.status || '').toLowerCase();
        const paymentStatus = (currentData.payment_status || '').toLowerCase();

        if (curStatus !== 'pending') return res.status(400).json({ error: 'not_pending' });
        if (paymentStatus !== 'settlement') return res.status(400).json({ error: 'not_paid' });

        const history = Array.isArray(currentData.history) ? currentData.history : [];
        history.push({
            status: 'approved_admin',
            by: req.user.uid,
            by_username: req.user.username,
            at: new Date(),
            note: req.body?.keterangan || '',
        });

        await ref.update({
            status: 'approved_admin',
            approved_admin_at: new Date(),
            approved_admin_by: req.user.uid,
            keterangan_admin: req.body?.keterangan || '',
            history,
            updatedAt: new Date(),
        });

        return res.json({ ok: true, status: 'approved_admin' });
    } catch (e) {
        console.error('[Admin API] Approve error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== ADMIN: DELETE ORDER ======================
router.delete('/api/v1/admin/orders/:id', requireAuthApi, requireRole(['admin']), async (req, res) => {
    try {
        await db.collection('orders').doc(req.params.id).delete();
        return res.json({ ok: true });
    } catch (e) {
        console.error('[Admin API] Delete order error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== ADMIN: LIST PRODUCTS ======================
router.get('/api/v1/admin/products', requireAuthApi, requireRole(['admin']), async (req, res) => {
    try {
        const snap = await db.collection('products').orderBy('sku').get();
        const products = snap.docs.map(d => d.data());
        return res.json({ products });
    } catch (e) {
        console.error('[Admin API] Products error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== ADMIN: CREATE PRODUCT ======================
router.post('/api/v1/admin/products', requireAuthApi, requireRole(['admin']), upload.single('gambar'), async (req, res) => {
    try {
        const { sku, barcode, nama_produk, satuan, divisi, harga_modal, harga_jual, pajak, stok } = req.body;
        if (!sku || !nama_produk || !satuan) {
            return res.status(400).json({ error: 'missing_fields', message: 'SKU, Nama Produk, Satuan wajib diisi' });
        }

        const skuExist = await db.collection('products').where('sku', '==', sku).limit(1).get();
        if (!skuExist.empty) return res.status(409).json({ error: 'sku_exists' });

        let gambarUrl = '';
        if (req.file) {
            const ext = path.extname(req.file.originalname || '').toLowerCase();
            const fileName = Date.now() + '-' + Math.random().toString(36).slice(2, 8) + ext;
            gambarUrl = await uploadToStorage(req.file.buffer, 'products/' + fileName, req.file.mimetype);
        }

        const id = randomUUID();
        const doc = {
            id, sku: sku.trim(), barcode: (barcode || '').trim(),
            nama_produk: nama_produk.trim(), satuan: satuan.trim(),
            divisi: (divisi || '').trim(), stok: Number(stok) || 0,
            harga_modal: parseFloat(harga_modal) || 0,
            harga_jual: parseFloat(harga_jual) || 0,
            pajak: parseFloat(pajak) || 0,
            gambar_url: gambarUrl,
            createdAt: new Date(), updatedAt: new Date()
        };
        await db.collection('products').doc(id).set(doc);
        return res.json({ ok: true, id });
    } catch (e) {
        console.error('[Admin API] Create product error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== ADMIN: UPDATE PRODUCT ======================
router.put('/api/v1/admin/products/:id', requireAuthApi, requireRole(['admin']), upload.single('gambar'), async (req, res) => {
    try {
        const id = req.params.id;
        const ref = db.collection('products').doc(id);
        const cur = await ref.get();
        if (!cur.exists) return res.status(404).json({ error: 'not_found' });

        const { sku, barcode, nama_produk, satuan, divisi, harga_modal, harga_jual, pajak, stok } = req.body;

        if (sku && sku !== cur.data().sku) {
            const skuExist = await db.collection('products').where('sku', '==', sku).limit(1).get();
            if (!skuExist.empty) return res.status(409).json({ error: 'sku_exists' });
        }

        const patch = {
            sku: sku ? sku.trim() : cur.data().sku,
            barcode: typeof barcode === 'string' ? barcode.trim() : (cur.data().barcode || ''),
            nama_produk: nama_produk ? nama_produk.trim() : cur.data().nama_produk,
            satuan: satuan ? satuan.trim() : cur.data().satuan,
            divisi: typeof divisi === 'string' ? divisi.trim() : (cur.data().divisi || ''),
            stok: stok !== undefined ? (Number(stok) || 0) : (cur.data().stok || 0),
            harga_modal: harga_modal !== undefined ? (parseFloat(harga_modal) || 0) : (cur.data().harga_modal || 0),
            harga_jual: harga_jual !== undefined ? (parseFloat(harga_jual) || 0) : (cur.data().harga_jual || 0),
            pajak: pajak !== undefined ? (parseFloat(pajak) || 0) : (cur.data().pajak || 0),
            updatedAt: new Date()
        };

        if (req.file) {
            await deleteFromStorage(cur.data().gambar_url);
            const ext = path.extname(req.file.originalname || '').toLowerCase();
            const fileName = Date.now() + '-' + Math.random().toString(36).slice(2, 8) + ext;
            patch.gambar_url = await uploadToStorage(req.file.buffer, 'products/' + fileName, req.file.mimetype);
        }

        await ref.update(patch);
        return res.json({ ok: true });
    } catch (e) {
        console.error('[Admin API] Update product error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== ADMIN: DELETE PRODUCT ======================
router.delete('/api/v1/admin/products/:id', requireAuthApi, requireRole(['admin']), async (req, res) => {
    try {
        const ref = db.collection('products').doc(req.params.id);
        const cur = await ref.get();
        if (cur.exists) {
            await deleteFromStorage(cur.data().gambar_url);
            await ref.delete();
        }
        return res.json({ ok: true });
    } catch (e) {
        console.error('[Admin API] Delete product error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== ADMIN: LIST USERS ======================
router.get('/api/v1/admin/users', requireAuthApi, requireRole(['admin']), async (req, res) => {
    try {
        const snap = await db.collection('users').orderBy('username').get();
        const users = snap.docs.map(d => {
            const u = d.data();
            return {
                id: d.id,
                username: u.username,
                role: u.role,
                nama_cabang: u.nama_cabang || '',
                provinsi: u.provinsi || '',
                kota: u.kota || '',
                jalan: u.jalan || '',
                createdAt: u.createdAt || null,
            };
        });
        return res.json({ users });
    } catch (e) {
        console.error('[Admin API] Users error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== ADMIN: CREATE USER ======================
router.post('/api/v1/admin/users', requireAuthApi, requireRole(['admin']), express.json(), async (req, res) => {
    try {
        const { username, password, role, nama_cabang, provinsi, kota, jalan } = req.body;
        if (!username || !password || !role) {
            return res.status(400).json({ error: 'missing_fields' });
        }
        if (!['admin', 'cabang', 'sales', 'gudang'].includes(role)) {
            return res.status(400).json({ error: 'invalid_role' });
        }

        const exist = await db.collection('users').where('username', '==', username).limit(1).get();
        if (!exist.empty) return res.status(409).json({ error: 'username_exists' });

        const id = randomUUID();
        const password_hash = await bcrypt.hash(password, 12);

        await db.collection('users').doc(id).set({
            id, username, password_hash, role,
            nama_cabang: nama_cabang || '', provinsi: provinsi || '',
            kota: kota || '', jalan: jalan || '',
            createdAt: new Date(), updatedAt: new Date(),
        });

        return res.json({ ok: true, id });
    } catch (e) {
        console.error('[Admin API] Create user error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== ADMIN: UPDATE USER ======================
router.put('/api/v1/admin/users/:id', requireAuthApi, requireRole(['admin']), express.json(), async (req, res) => {
    try {
        const id = req.params.id;
        const docRef = db.collection('users').doc(id);
        const doc = await docRef.get();
        if (!doc.exists) return res.status(404).json({ error: 'not_found' });

        const { username, password, role, nama_cabang, provinsi, kota, jalan } = req.body;

        if (username && username !== doc.data().username) {
            const exist = await db.collection('users').where('username', '==', username).limit(1).get();
            if (!exist.empty) return res.status(409).json({ error: 'username_exists' });
        }

        const patch = {
            username: username || doc.data().username,
            role: role || doc.data().role,
            nama_cabang: nama_cabang ?? doc.data().nama_cabang,
            provinsi: provinsi ?? doc.data().provinsi,
            kota: kota ?? doc.data().kota,
            jalan: jalan ?? doc.data().jalan,
            updatedAt: new Date(),
        };
        if (password && password.trim()) {
            patch.password_hash = await bcrypt.hash(password, 12);
        }

        await docRef.update(patch);
        return res.json({ ok: true });
    } catch (e) {
        console.error('[Admin API] Update user error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== ADMIN: DELETE USER ======================
router.delete('/api/v1/admin/users/:id', requireAuthApi, requireRole(['admin']), async (req, res) => {
    try {
        await db.collection('users').doc(req.params.id).delete();
        return res.json({ ok: true });
    } catch (e) {
        console.error('[Admin API] Delete user error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

// ====================== ADMIN: LIST SHIPMENTS ======================
router.get('/api/v1/admin/shipments', requireAuthApi, requireRole(['admin']), async (req, res) => {
    try {
        const snap = await db.collection('shipments').orderBy('createdAt', 'desc').get();
        const shipments = snap.docs.map(d => {
            const s = d.data();
            return {
                id: s.id || d.id,
                kode_pengiriman: s.kode_pengiriman || '',
                po_number: s.po_number || '',
                so_number: s.so_number || '',
                penerima_id: s.penerima || '',
                pengirim_id: s.pengirim || '',
                status: s.status || 'dikirim',
                total_harga: s.total_harga || 0,
                jumlah_item: Array.isArray(s.data_barang) ? s.data_barang.length : 0,
                keterangan: s.keterangan || '',
                createdAt: s.createdAt || null,
            };
        });

        // Enrich with user names
        const allUserIds = [...new Set([
            ...shipments.map(s => s.penerima_id),
            ...shipments.map(s => s.pengirim_id),
        ].filter(Boolean))];
        const usersMap = await getUsersMapByIds(allUserIds);

        for (const s of shipments) {
            if (usersMap[s.penerima_id]) {
                s.penerima_nama = usersMap[s.penerima_id].nama_cabang || '';
                s.penerima_username = usersMap[s.penerima_id].username || s.penerima_id;
            }
            if (usersMap[s.pengirim_id]) {
                s.pengirim_username = usersMap[s.pengirim_id].username || s.pengirim_id;
            }
        }

        return res.json({ shipments });
    } catch (e) {
        console.error('[Admin API] Shipments error:', e);
        return res.status(500).json({ error: 'server_error' });
    }
});

module.exports = router;
