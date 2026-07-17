# API Documentation — Aqua Japan (web_aqua)

Dokumentasi endpoint API yang dipanggil aplikasi Flutter (`flutter_aqua`).
Base URL default: `http://192.168.8.102:3000` (dapat diubah dari pengaturan Flutter).
Semua endpoint API diawali `/api/v1/`.

## Autentikasi

Kecuali `POST /api/v1/auth/login`, semua endpoint membutuhkan header:

```
Authorization: Bearer <JWT_TOKEN>
```

Token didapat dari login dan disimpan di `SharedPreferences` (Flutter) / cookie `__session` (web).

---

## 1. Auth

### POST `/api/v1/auth/login`
Login user (cabang / sales / gudang / admin).

**Request body (JSON):**
```json
{ "username": "string", "password": "string" }
```

**Response 200:**
```json
{
  "token": "eyJ...",
  "user": { "id": "uid", "username": "cabang1", "role": "cabang", "nama_cabang": "..." }
}
```

### GET `/api/v1/auth/me`
Mengembalikan profil user dari token aktif. `200: { "user": {...} }`

### PUT `/api/v1/auth/profile`
Update profil cabang (nama_cabang, provinsi, kota, jalan, password≥6). `200: { success: true }`

---

## 2. Cabang (`role: cabang`)

| Method | Path | Fungsi |
|--------|------|--------|
| GET | `/api/v1/cabang/dashboard` | Ringkasan stok masuk & stok tersedia cabang |
| GET | `/api/v1/cabang/shipments` | Daftar pengiriman masuk (status ≠ draft) |
| GET | `/api/v1/cabang/shipments/:kode_pengiriman` | Detail 1 resi + daftar barang |
| POST | `/api/v1/cabang/shipments/:kode_pengiriman/confirm` | Konfirmasi terima/tolak (multipart: `aksi`, `keterangan`, `items_json`, `location_json`, `photos[]`) |
| GET | `/api/v1/cabang/products` | Daftar produk (untuk order) |
| POST | `/api/v1/cabang/orders` | Buat pesanan + bayar Midtrans (`items[]`, `keterangan`) |
| GET | `/api/v1/cabang/orders` | Riwayat pesanan cabang |
| POST | `/api/v1/cabang/orders/:id/pay` | Generate ulang token pembayaran Midtrans |
| POST | `/api/v1/cabang/orders/:id/confirm-payment` | Konfirmasi pembayaran (update `payment_status`) |
| GET | `/api/v1/cabang/branch-products` | Stok produk di toko cabang (`branch_stocks`) |
| POST | `/api/v1/cabang/sales` | Penjualan lokal (`items[]`, `total_bayar`) |
| GET | `/api/v1/cabang/sales` | Riwayat penjualan cabang |

**Field `confirm` (POST .../shipments/:kode/confirm):**
- `aksi`: `"diterima"` | `"ditolak"`
- `items_json`: `[{ "idx": 0, "qty_diterima": 5, "catatan": "..." }]`
- `location_json`: `{ "lat": -6.2, "lng": 106.8, "accuracy": 12.5, "address": "...", "captured_at": "ISO8601" }`
- `photos[]`: file gambar (max 5), diupload ke Cloudinary

**Validasi Lokasi GPS (Geofencing Opsi A):**
- Koordinat `lat`/`lng` wajib berupa angka finite,否则 `400 invalid_location_coords`.
- Jika `accuracy` > **100 m**, konfirmasi ditolak dengan `400 location_accuracy_too_low`
  (pesan: "Akurasi lokasi Xm melebihi batas 100m...").
- Jika lolos, snapshot lokasi menyimpan flag `lokasi_terverifikasi: true` (atau `false` bila akurasi tidak dikirim).
- Response menyertakan `lokasi_terverifikasi` (boolean).

---

## 3. Sales (`role: sales`)

| Method | Path | Fungsi |
|--------|------|--------|
| GET | `/api/v1/sales/orders` | Daftar seluruh pesanan |
| POST | `/api/v1/sales/orders` | Buat pesanan untuk cabang (`items[]`, `cabang_id` wajib) + token Midtrans |

---

## 4. Gudang (`role: gudang`)

| Method | Path | Fungsi |
|--------|------|--------|
| GET | `/api/v1/gudang/orders` | Daftar order siap dikemas (`approved_admin`/`dipaket`/`dikirim`) |
| POST | `/api/v1/gudang/orders/:id/pack` | Packing order → status `dipaket` |
| POST | `/api/v1/gudang/orders/:id/send` | Kirim order → buat `shipments` (kode resi) → status `dikirim` |

---

## 5. Midtrans Webhook

### POST `/api/v1/midtrans/notification`
Dipanggil otomatis oleh Midtrans saat status pembayaran berubah.
- `settlement` / `capture+accept` → `payment_status = settlement`
- `cancel` / `deny` / `expire` → `status = ditolak` **+ stok produk dikembalikan**

---

## Kode Status Umum

| Status | Arti |
|--------|------|
| 200 | Sukses |
| 400 | Request tidak valid (field kurang / stok tidak cukup) |
| 401 | Token tidak ada / tidak valid |
| 403 | Bukan hak akses role ini / bukan resi milik sendiri |
| 404 | Data tidak ditemukan |
| 409 | Sudah dikonfirmasi (confirm ganda) |
| 500 | Error server |

---

## Catatan Integrasi Stok

- Stok pusat (`products.stok`) **dipotong saat order dibuat** (cabang & sales).
- Jika pembayaran `expire/cancel/deny`, stok **dikembalikan** via webhook.
- Saat cabang **menerima** kiriman → stok masuk ke `branch_stocks`.
- Saat cabang **menolak** kiriman → stok pusat **dikembalikan**.
