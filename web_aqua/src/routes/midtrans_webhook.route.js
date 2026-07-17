const express = require('express');
const router = express.Router();
const admin = require('firebase-admin');
const { db } = require('../firebaseAdmin');
const { coreApi } = require('../midtransClient');

router.use(express.json());

router.post('/api/v1/midtrans/notification', async (req, res) => {
    try {
        const statusResponse = await coreApi.transaction.notification(req.body);

        const orderId = statusResponse.order_id;
        const transactionStatus = statusResponse.transaction_status;
        const fraudStatus = statusResponse.fraud_status;

        console.log(`[Midtrans] Notifikasi diterima untuk order ${orderId}: status ${transactionStatus}`);

        const snap = await db.collection('orders')
            .where('midtrans_order_id', '==', orderId)
            .limit(1)
            .get();

        if (snap.empty) {
            console.warn(`[Midtrans] Order dengan midtrans_order_id ${orderId} tidak ditemukan.`);
            return res.status(200).json({ status: 'ok' });
        }

        const doc = snap.docs[0];
        const currentData = doc.data();

        if (['selesai', 'dikirim', 'diterima', 'ditolak'].includes(currentData.status)) {
            console.log(`[Midtrans] Order ${orderId} sudah ${currentData.status}, lewati.`);
            return res.status(200).json({ status: 'ok' });
        }

        const isSuccess = transactionStatus === 'settlement' ||
            (transactionStatus === 'capture' && fraudStatus === 'accept');

        if (isSuccess) {
            // Di flow baru: payment hanya update payment_status, status tetap 'pending'
            // Order akan lanjut ke sales → admin → gudang secara sequential
            await doc.ref.update({
                payment_status: transactionStatus,
                updatedAt: new Date()
            });

            console.log(`[Midtrans] Order ${orderId} -> pembayaran settlement, menunggu persetujuan sales`);
        } else if (['cancel', 'deny', 'expire'].includes(transactionStatus)) {
            // Kembalikan stok pusat yang sudah dipotong saat order dibuat (sales)
            try {
                const items = Array.isArray(currentData.items) ? currentData.items : [];
                if (items.length) {
                    const batch = db.batch();
                    let hasOp = false;
                    for (const it of items) {
                        const qty = Number(it.qty || it.jumlah || 0);
                        const pid = it.product_id || it.produk_id || it.productId || it.id_produk;
                        if (qty > 0 && pid) {
                            batch.update(db.collection('products').doc(pid), {
                                stok: admin.firestore.FieldValue.increment(qty),
                                updatedAt: new Date()
                            });
                            hasOp = true;
                        }
                    }
                    if (hasOp) await batch.commit();
                }
            } catch (stockErr) {
                console.error(`[Midtrans] Gagal restore stok order ${orderId}:`, stockErr);
            }

            await doc.ref.update({
                status: 'ditolak',
                payment_status: transactionStatus,
                updatedAt: new Date()
            });
            console.log(`[Midtrans] Order ${orderId} -> ditolak, stok dikembalikan`);
        } else {
            await doc.ref.update({
                payment_status: transactionStatus,
                updatedAt: new Date()
            });
        }

        res.status(200).json({ status: 'ok' });
    } catch (e) {
        console.error('Error handling midtrans notification:', e);
        res.status(500).json({ error: e.message });
    }
});

module.exports = router;
