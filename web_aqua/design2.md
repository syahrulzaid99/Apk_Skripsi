# Octavia — Design System Documentation

> Learning Management Dashboard UI  
> Audience: Students (Grade 1–12)  
> Page job: Satu halaman sentral untuk memantau progress belajar, jadwal harian, dan akses kursus aktif.

---

## 1. Color Palette

| Token | Hex | Peran |
|---|---|---|
| `--color-primary` | `#3B82F6` | Aksi utama, highlight bar aktif, tombol CTA |
| `--color-primary-light` | `#93C5FD` | Bar chart non-aktif, card background secondary |
| `--color-accent-pink` | `#F472B6` | Data series "Grammar" pada chart |
| `--color-accent-green` | `#4ADE80` | Data series "Vocabulary" pada chart |
| `--color-accent-yellow` | `#FDE68A` | Event card kalender (Introduction to Spanish) |
| `--color-bg-base` | `#F5F7FA` | Background halaman utama |
| `--color-bg-card` | `#FFFFFF` | Background semua card/panel |
| `--color-bg-nav` | `#FFFFFF` | Sidebar background |
| `--color-nav-active` | `#EFF6FF` | Highlight item navigasi aktif |
| `--color-premium-bg` | `#1E2A4A` | Card "Buy Premium" di sidebar bawah |
| `--color-text-primary` | `#1E293B` | Heading utama, label penting |
| `--color-text-secondary` | `#64748B` | Subtext, label chart, metadata |
| `--color-text-muted` | `#94A3B8` | Timestamp, placeholder |
| `--color-badge-pro` | `#6366F1` | Badge "Pro" pada menu Analysis |
| `--color-badge-msg` | `#3B82F6` | Badge count "27" pada menu Messages |

---

## 2. Typography

### Font Family
```
Display / Heading : Poppins (Bold 700, SemiBold 600)
Body / UI Label   : Inter (Regular 400, Medium 500)
Data / Caption    : Inter (Regular 400, size 11–12px)
```

### Type Scale

| Role | Size | Weight | Color |
|---|---|---|---|
| Page title (H1) | 32–36px | 700 | `--color-text-primary` |
| Section heading (H2) | 18px | 600 | `--color-text-primary` |
| Card label | 14px | 500 | `--color-text-primary` |
| Body / sublabel | 13px | 400 | `--color-text-secondary` |
| Caption / meta | 11–12px | 400 | `--color-text-muted` |
| Badge / pill | 10–11px | 600 | White on colored bg |

### Penggunaan
- **Heading halaman** (`H1`) ditulis besar, multi-line, dengan emoji sebagai elemen visual yang ringan.
- **Section title** (`Your Courses`, `Daily activity`) pakai weight 600, tidak dibold penuh.
- **Label navigasi** pakai Inter 14px Medium.

---

## 3. Spacing & Layout

### Grid System
```
Layout   : 3-column (Sidebar | Main Content | Right Panel)
Sidebar  : 200–210px, fixed
Main     : flex-grow, max ~680px
Right    : 280–300px, fixed
```

### Spacing Scale (base 4px)
```
xs   : 4px
sm   : 8px
md   : 16px
lg   : 24px
xl   : 32px
2xl  : 48px
```

### Padding Card
- Card padding: `20–24px` semua sisi
- Gap antar card: `16px`
- Gap antar section: `24–32px`

---

## 4. Border Radius

| Elemen | Radius |
|---|---|
| Card / Panel | `16px` |
| Button / Badge | `8–10px` |
| Nav item aktif | `10–12px` |
| Avatar | `50%` (lingkaran) |
| Progress ring | `50%` |
| Chart bar | `6px` top-only |
| Event pill (kalender) | `8px` |

---

## 5. Shadows & Elevation

```css
/* Card shadow - subtle, diffuse */
box-shadow: 0 2px 12px rgba(0, 0, 0, 0.06);

/* Popup / Notification card */
box-shadow: 0 8px 24px rgba(0, 0, 0, 0.12);

/* Sidebar - no shadow (flat, bg berbeda dari konten) */
```

---

## 6. Component Inventory

### 6.1 Sidebar Navigation
- Logo + nama app di atas
- Nav list: icon + label, item aktif diberi bg `--color-nav-active` + teks biru
- Badge inline (Pro = ungu pill, angka = biru pill)
- Settings & Logout di bawah, warna muted
- Card premium `--color-premium-bg` paling bawah: CTA "Buy Premium", white text, teks kecil + ikon bintang

### 6.2 Top Bar (Header)
- Heading besar kiri: `"Let's Start Your New Course 😍"`
- Icon kanan: search (outline), notifikasi (dengan dot biru = unread)

### 6.3 Performance Bar Chart
- Bar chart vertikal, 5–6 bars
- Bar aktif: `--color-primary` lebih gelap + lebih tinggi
- Bar non-aktif: `--color-primary-light`
- Tooltip bubble di atas bar tertinggi: background gelap, white text, radius pill
- Subtext di bawah: "6 course completed"

### 6.4 Time Spent Line/Bar Chart
- Multi-series: pink (Grammar), blue (Vocabulary), green (Listening)
- Axis X: tanggal Dec 17–21
- Legend di kanan: titik berwarna + label + jam
- Filter dropdown: "December" + panah kiri-kanan

### 6.5 Course List Item
- Layout horizontal: teks kiri (nama + jumlah lesson) + ikon panah kanan
- Item aktif: background biru muda `#EFF6FF`, border atau highlight subtle
- Item non-aktif: white background
- Border radius `12px`

### 6.6 User Profile Panel (kanan atas)
- Avatar lingkaran + nama + role
- Progress ring trio: 3 lingkaran kecil (French 70%, Spanish 80%, Italian 60%)
  - Setiap ring: persen di tengah, label di bawah, sub-label (Beginner)

### 6.7 Daily Activity (Kalender/Timeline)
- Header: "Daily Activity" + ikon kalender + tanggal hari ini
- Timeline vertikal kiri (jam), event card sebagai blok warna di kanan
- Card warna kuning: "Introduction to Spanish" 10:40–13:00
- Card warna biru/ungu muda: "English for travel" 10:40–13:00

### 6.8 Popup Notification Card
- Floating di atas konten main
- Background putih, shadow kuat
- Icon kecil kiri atas (kategori), tombol tutup (×) kanan atas
- Heading bold, subtext kecil, tombol CTA "Subscribe"
- Elemen ilustrasi 3D (tangan) sebagai visual pendukung

---

## 7. Iconography

- Style: **outline icons**, stroke 1.5–2px
- Ukuran di nav: 18–20px
- Library referensi: [Heroicons](https://heroicons.com) atau [Lucide](https://lucide.dev)
- Ikon sidebar: Dashboard, Classes, Schedule, Homeworks, Analysis, Messages, Settings, Log out

---

## 8. Data Visualization

| Chart | Tipe | Warna |
|---|---|---|
| Performance | Bar chart vertikal | Blue scale |
| Time Spent | Multi-bar / line combo | Pink, Blue, Green |
| Progress bahasa | Circular progress ring | Per warna per bahasa |

- Semua chart: tanpa grid line kuat (subtle atau transparan)
- Label data langsung di atas/samping elemen, bukan di axis panjang

---

## 9. Motion & Interaction

- Bar chart: grow dari bawah saat load (`transform: scaleY` + `transition`)
- Nav item hover: bg muncul smooth (`transition: background 150ms ease`)
- Card course hover: subtle shadow lift + `translateY(-2px)`
- Progress ring: animasi fill saat pertama render (stroke-dashoffset ke 0)
- Popup: masuk dengan `fade-in + slideUp` ringan (`opacity 0→1`, `translateY 8px→0`)

---

## 10. Responsive Behavior

| Breakpoint | Behavior |
|---|---|
| `> 1280px` | Full 3-column layout |
| `1024px` | Right panel collapse, main expand |
| `768px` | Sidebar collapse jadi icon-only |
| `< 640px` | Sidebar hidden, bottom nav muncul |

---

## 11. Design Signature

> **Elemen khas: Circular Progress Ring trio** pada user profile panel — tiga cincin kecil berdampingan dengan persen di tengah, masing-masing mewakili satu bahasa. Elemen ini bukan sekadar data, tapi identitas visual "progress belajar" yang intuitif dan bisa dikenali sekilas.

Dikombinasikan dengan bar chart bertingkat dan warna pastel yang ringan, keseluruhan UI menyampaikan satu pesan: **belajar itu terstruktur, terpantau, dan tidak menegangkan.**

---

*Generated from UI screenshot — Octavia Learning Dashboard*