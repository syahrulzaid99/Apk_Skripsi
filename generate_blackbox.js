const {
  Document,
  Packer,
  Paragraph,
  TextRun,
  Table,
  TableRow,
  TableCell,
  WidthType,
  BorderStyle,
  AlignmentType,
  ImageRun,
  PageBreak,
  HeadingLevel,
  ShadingType,
  VerticalAlign,
} = require("docx");
const fs = require("fs");
const path = require("path");

const root = __dirname;
const outputPath = path.join(root, "Pengujian_Black_Box_Aqua_Japan.docx");
const sampleImagePath = "C:\\Users\\Muh\\AppData\\Local\\Temp\\codex-clipboard-67d97c5c-e94e-400f-ad1f-24f704d186eb.png";

const flows = [
  {
    title: "Login User",
    actor: "User",
    whitebox: ["Mulai", "Buka Aplikasi", "Pilih Masuk", "Tampilkan Form Login", "Input Email dan Password", "Klik Masuk", "Validasi Data", "Baca Akun", "Valid?", "Proses berhasil", "Tampilkan Pesan Error", "Selesai"],
    cases: [
      ["User membuka aplikasi dan memilih Masuk", "✓", "Form login tampil dan dapat digunakan."],
      ["Email dan password valid", "✓", "Sistem menerima data, membaca akun, lalu mengarahkan pengguna ke halaman utama."],
      ["Email/password salah atau kosong", "✓", "Sistem menolak proses login dan menampilkan pesan kesalahan."],
    ],
    sample: true,
  },
  {
    title: "Pengaturan Server dan Tema",
    actor: "Pengguna",
    whitebox: ["Mulai", "Buka Pengaturan", "Tampilkan Pengaturan", "Pilih Server atau Tema", "Simpan Konfigurasi", "Perbarui Preferensi", "Selesai"],
    cases: [
      ["Pengguna membuka menu Pengaturan", "✓", "Halaman pengaturan server dan tema tampil."],
      ["Pengguna memilih server/tema lalu menyimpan", "✓", "Preferensi tersimpan dan diterapkan pada aplikasi."],
    ],
  },
  {
    title: "Admin Dashboard",
    actor: "Admin",
    whitebox: ["Mulai", "Buka Dashboard", "Ambil Ringkasan", "Baca Data Dashboard", "Tampilkan Metrik", "Selesai"],
    cases: [
      ["Admin membuka Dashboard", "✓", "Sistem mengambil ringkasan dan menampilkan metrik dashboard."],
      ["Data ringkasan tidak tersedia", "✓", "Sistem tetap menampilkan halaman dengan kondisi kosong atau pesan informasi."],
    ],
  },
  {
    title: "Admin Kelola Pesanan",
    actor: "Admin",
    whitebox: ["Mulai", "Buka Pesanan", "Ambil Daftar Pesanan", "Pilih Pesanan", "Tampilkan Detail", "Pilih Tindakan", "Validasi Tindakan", "Simpan Perubahan", "Tampilkan Pesan Error", "Selesai"],
    cases: [
      ["Admin membuka Pesanan dan memilih pesanan", "✓", "Daftar pesanan dan detail pesanan tampil."],
      ["Admin memilih tindakan yang valid", "✓", "Perubahan berhasil divalidasi dan disimpan."],
      ["Tindakan tidak valid atau penyimpanan gagal", "✓", "Sistem tidak menyimpan perubahan dan menampilkan pesan error."],
    ],
  },
  {
    title: "Admin Kelola Pengguna",
    actor: "Admin",
    whitebox: ["Mulai", "Buka Users", "Ambil Daftar Pengguna", "Pilih Tindakan", "Isi Data Pengguna", "Validasi Data", "Simpan Akun", "Tampilkan Pesan Error", "Selesai"],
    cases: [
      ["Admin membuka Users dan memilih tambah/ubah pengguna", "✓", "Daftar pengguna dan form data tampil."],
      ["Data pengguna lengkap dan valid", "✓", "Akun berhasil divalidasi dan disimpan."],
      ["Data wajib kosong atau format tidak valid", "✓", "Sistem menampilkan pesan error dan tidak menyimpan akun."],
    ],
  },
  {
    title: "Admin Kelola Produk dan Divisi",
    actor: "Admin",
    whitebox: ["Mulai", "Buka Master Data", "Ambil Produk dan Divisi", "Pilih Tambah atau Ubah", "Isi Data Produk", "Validasi Data", "Simpan Master Data", "Tampilkan Pesan Error", "Selesai"],
    cases: [
      ["Admin membuka Master Data", "✓", "Data produk dan divisi tampil."],
      ["Data produk/divisi valid", "✓", "Master data berhasil disimpan."],
      ["Data produk/divisi tidak lengkap", "✓", "Sistem menampilkan error dan membatalkan penyimpanan."],
    ],
  },
  {
    title: "Admin Lihat Pengiriman",
    actor: "Admin",
    whitebox: ["Mulai", "Buka Pengiriman", "Ambil Data Pengiriman", "Baca Data Shipment", "Gunakan Filter", "Tampilkan Detail", "Selesai"],
    cases: [
      ["Admin membuka Pengiriman", "✓", "Data pengiriman berhasil ditampilkan."],
      ["Admin menggunakan filter yang sesuai", "✓", "Daftar terfilter dan detail pengiriman dapat dibuka."],
      ["Filter tidak menemukan data", "✓", "Sistem menampilkan kondisi data kosong tanpa error."],
    ],
  },
  {
    title: "Admin Laporan",
    actor: "Admin",
    whitebox: ["Mulai", "Buka Laporan", "Ambil Data Laporan", "Baca Data Penjualan", "Pilih Jenis Laporan", "Tampilkan Ringkasan", "Unduh Laporan", "Selesai"],
    cases: [
      ["Admin membuka Laporan dan memilih jenis laporan", "✓", "Ringkasan laporan penjualan tampil."],
      ["Admin menekan Unduh Laporan", "✓", "File laporan berhasil dibuat dan diunduh."],
    ],
  },
  {
    title: "Admin Data Cabang",
    actor: "Admin",
    whitebox: ["Mulai", "Buka Data Cabang", "Ambil Data Cabang", "Baca Stok Cabang", "Pilih Area", "Tampilkan Detail Cabang", "Selesai"],
    cases: [
      ["Admin membuka Data Cabang", "✓", "Data cabang dan stok cabang tampil."],
      ["Admin memilih area yang tersedia", "✓", "Detail cabang sesuai area ditampilkan."],
    ],
  },
  {
    title: "Cabang Dashboard",
    actor: "Cabang",
    whitebox: ["Mulai", "Buka Dashboard", "Ambil Ringkasan", "Baca Data Cabang", "Tampilkan Dashboard", "Selesai"],
    cases: [
      ["Cabang membuka Dashboard", "✓", "Sistem mengambil data cabang dan menampilkan dashboard."],
      ["Data cabang kosong", "✓", "Dashboard tetap tampil dengan nilai kosong atau informasi yang sesuai."],
    ],
  },
  {
    title: "Cabang Stok Masuk dan Penerimaan",
    actor: "Cabang",
    whitebox: ["Mulai", "Buka Stok Masuk", "Ambil Daftar Kiriman", "Baca Data Shipment", "Pilih Kiriman", "Tampilkan Detail", "Ambil Lokasi dan Foto", "Validasi Penerimaan", "Simpan Penerimaan", "Tampilkan Pesan Error", "Selesai"],
    cases: [
      ["Cabang membuka Stok Masuk dan memilih kiriman", "✓", "Daftar kiriman serta detail penerimaan tampil."],
      ["Lokasi, foto, dan data penerimaan valid", "✓", "Penerimaan berhasil divalidasi dan disimpan."],
      ["Lokasi/foto wajib tidak tersedia atau data tidak valid", "✓", "Sistem menampilkan pesan error dan tidak menyimpan penerimaan."],
    ],
  },
  {
    title: "Cabang Scan Pengiriman",
    actor: "Cabang",
    whitebox: ["Mulai", "Buka Scan", "Scan QR atau Input Kode", "Cari Pengiriman", "Baca Data Shipment", "Kiriman Ditemukan?", "Tampilkan Detail", "Tampilkan Pesan Error", "Selesai"],
    cases: [
      ["Cabang membuka Scan dan memasukkan QR/kode yang terdaftar", "✓", "Sistem menemukan kiriman dan menampilkan detailnya."],
      ["QR/kode tidak terdaftar atau tidak terbaca", "✓", "Sistem menampilkan pesan error dan tidak menampilkan detail kiriman."],
    ],
  },
  {
    title: "Cabang Buat Order",
    actor: "Cabang",
    whitebox: ["Mulai", "Buka Order", "Ambil Katalog Produk", "Baca Data Produk", "Pilih Produk dan Jumlah", "Isi Keterangan", "Validasi Order", "Simpan Order", "Tampilkan Status", "Tampilkan Pesan Error", "Selesai"],
    cases: [
      ["Cabang membuka Order dan memilih produk", "✓", "Katalog produk dan pilihan jumlah tampil."],
      ["Produk, jumlah, dan keterangan valid", "✓", "Order berhasil divalidasi, disimpan, dan status ditampilkan."],
      ["Jumlah tidak valid atau data wajib kosong", "✓", "Sistem menampilkan pesan error dan tidak menyimpan order."],
    ],
  },
  {
    title: "Cabang Pembayaran Order",
    actor: "Cabang",
    whitebox: ["Mulai", "Buka Daftar Order", "Ambil Data Order", "Baca Data Order", "Pilih Order Belum Bayar", "Buat Transaksi", "Proses Midtrans", "Validasi Pembayaran", "Perbarui Status Bayar", "Tampilkan Pembayaran Gagal", "Selesai"],
    cases: [
      ["Cabang memilih order yang belum dibayar", "✓", "Data order dan transaksi pembayaran tampil."],
      ["Pembayaran berhasil divalidasi", "✓", "Status pembayaran diperbarui menjadi berhasil/lunas."],
      ["Pembayaran gagal atau dibatalkan", "✓", "Sistem menampilkan pembayaran gagal dan status order tidak disalahartikan sebagai lunas."],
    ],
  },
  {
    title: "Cabang Penjualan",
    actor: "Cabang",
    whitebox: ["Mulai", "Buka Penjualan", "Ambil Stok Cabang", "Baca Data Stok", "Pilih Produk dan Jumlah", "Validasi Stok", "Simpan Penjualan", "Perbarui Stok", "Tampilkan Hasil", "Tampilkan Pesan Error", "Selesai"],
    cases: [
      ["Cabang membuka Penjualan dan memilih produk", "✓", "Data stok dan pilihan produk tampil."],
      ["Jumlah penjualan tidak melebihi stok", "✓", "Penjualan disimpan, stok diperbarui, dan hasil ditampilkan."],
      ["Jumlah melebihi stok atau data tidak valid", "✓", "Sistem menampilkan error dan stok tidak berubah."],
    ],
  },
  {
    title: "Cabang Kelola Profil",
    actor: "Cabang",
    whitebox: ["Mulai", "Buka Profil", "Ambil Data Profil", "Baca Data User", "Ubah Data Profil", "Validasi Data", "Perbarui Profil", "Tampilkan Pesan Error", "Selesai"],
    cases: [
      ["Cabang membuka Profil", "✓", "Data profil pengguna tampil."],
      ["Perubahan profil valid", "✓", "Profil berhasil divalidasi dan diperbarui."],
      ["Data profil tidak valid", "✓", "Sistem menampilkan error dan mempertahankan data sebelumnya."],
    ],
  },
  {
    title: "Gudang Dashboard",
    actor: "Gudang",
    whitebox: ["Mulai", "Buka Dashboard", "Ambil Ringkasan Gudang", "Baca Data Order", "Tampilkan Dashboard", "Selesai"],
    cases: [
      ["Gudang membuka Dashboard", "✓", "Ringkasan gudang dan data order tampil."],
      ["Data order belum tersedia", "✓", "Dashboard menampilkan kondisi kosong secara informatif."],
    ],
  },
  {
    title: "Gudang Packing dan Kirim Order",
    actor: "Gudang",
    whitebox: ["Mulai", "Buka Pengemasan", "Ambil Order Gudang", "Baca Data Order", "Pilih Order", "Periksa Item", "Tandai Dikemas", "Simpan Status Packing", "Konfirmasi Kirim", "Selesai"],
    cases: [
      ["Gudang membuka Pengemasan dan memilih order", "✓", "Detail order dan item yang harus diperiksa tampil."],
      ["Item sesuai, ditandai dikemas, lalu konfirmasi kirim", "✓", "Status packing tersimpan dan status pengiriman diperbarui."],
      ["Item tidak sesuai atau konfirmasi dibatalkan", "✓", "Sistem tidak memperbarui status kirim sebelum proses valid."],
    ],
  },
  {
    title: "Gudang Riwayat Pengiriman",
    actor: "Gudang",
    whitebox: ["Mulai", "Buka Riwayat", "Ambil Riwayat Shipment", "Baca Data Shipment", "Gunakan Filter", "Tampilkan Detail", "Selesai"],
    cases: [
      ["Gudang membuka Riwayat", "✓", "Riwayat shipment tampil."],
      ["Gudang menggunakan filter yang sesuai", "✓", "Hasil filter dan detail pengiriman tampil."],
    ],
  },
  {
    title: "Sales Dashboard",
    actor: "Sales",
    whitebox: ["Mulai", "Buka Dashboard", "Ambil Ringkasan Sales", "Baca Data Order", "Tampilkan Dashboard", "Selesai"],
    cases: [
      ["Sales membuka Dashboard", "✓", "Ringkasan sales dan data order tampil."],
      ["Data order kosong", "✓", "Dashboard tetap tampil dengan kondisi kosong yang informatif."],
    ],
  },
  {
    title: "Sales Kelola Order Cabang",
    actor: "Sales",
    whitebox: ["Mulai", "Buka Daftar Order", "Ambil Order Sales", "Baca Data Order", "Pilih Order", "Pilih Konfirmasi atau Tolak", "Validasi Tindakan", "Perbarui Status Order", "Tampilkan Pesan Error", "Selesai"],
    cases: [
      ["Sales membuka daftar order dan memilih order", "✓", "Detail order tampil dan tindakan konfirmasi/tolak tersedia."],
      ["Sales memilih tindakan yang valid", "✓", "Status order berhasil diperbarui."],
      ["Tindakan tidak valid atau pembaruan gagal", "✓", "Sistem menampilkan pesan error dan status order tetap."],
    ],
  },
  {
    title: "Sales Pembayaran Order",
    actor: "Sales",
    whitebox: ["Mulai", "Buka Daftar Order", "Ambil Data Order", "Baca Data Order", "Pilih Order Belum Bayar", "Buat Transaksi", "Proses Midtrans", "Validasi Pembayaran", "Perbarui Status Bayar", "Tampilkan Pembayaran Gagal", "Selesai"],
    cases: [
      ["Sales memilih order yang belum dibayar", "✓", "Order dan proses transaksi tampil."],
      ["Pembayaran berhasil", "✓", "Status bayar diperbarui sesuai hasil pembayaran."],
      ["Pembayaran gagal", "✓", "Pesan pembayaran gagal tampil dan status tidak berubah menjadi lunas."],
    ],
  },
  {
    title: "Sales Laporan",
    actor: "Sales",
    whitebox: ["Mulai", "Buka Laporan", "Ambil Data Laporan", "Baca Data Order", "Atur Filter", "Tampilkan Ringkasan", "Unduh Laporan", "Selesai"],
    cases: [
      ["Sales membuka Laporan dan mengatur filter", "✓", "Ringkasan laporan order sesuai filter tampil."],
      ["Sales menekan Unduh Laporan", "✓", "File laporan berhasil dibuat dan diunduh."],
    ],
  },
  {
    title: "Sales Tracking Pengiriman",
    actor: "Sales",
    whitebox: ["Mulai", "Buka Tracking", "Ambil Status Pengiriman", "Baca Data Shipment", "Cari Order atau Resi", "Tampilkan Timeline", "Selesai"],
    cases: [
      ["Sales mencari order/resi yang terdaftar", "✓", "Status pengiriman dan timeline tampil."],
      ["Order/resi tidak ditemukan", "✓", "Sistem menampilkan informasi bahwa data tidak ditemukan."],
    ],
  },
  {
    title: "Logout",
    actor: "Pengguna",
    whitebox: ["Mulai", "Klik Keluar", "Konfirmasi Keluar", "Hapus Token Lokal", "Arahkan ke Login", "Batalkan proses", "Selesai"],
    cases: [
      ["Pengguna menekan Keluar lalu memilih konfirmasi", "✓", "Token lokal dihapus dan pengguna diarahkan ke halaman Login."],
      ["Pengguna membatalkan konfirmasi keluar", "✓", "Proses dibatalkan dan pengguna tetap berada di halaman sebelumnya."],
    ],
  },
];

const colors = {
  navy: "1F4E78",
  blue: "D9EAF7",
  light: "F3F6F9",
  gray: "666666",
  border: "222222",
};

function textParagraph(text, opts = {}) {
  return new Paragraph({
    alignment: opts.alignment || AlignmentType.LEFT,
    spacing: opts.spacing || { before: 0, after: 60, line: 240 },
    children: [new TextRun({ text, font: "Times New Roman", size: opts.size || 22, bold: !!opts.bold, italics: !!opts.italics, color: opts.color })],
  });
}

function cell(text, opts = {}) {
  return new TableCell({
    width: opts.width ? { size: opts.width, type: WidthType.DXA } : undefined,
    columnSpan: opts.columnSpan,
    verticalAlign: opts.verticalAlign || VerticalAlign.CENTER,
    shading: opts.shading ? { type: ShadingType.CLEAR, fill: opts.shading } : undefined,
    margins: { top: 90, bottom: 90, left: 100, right: 100 },
    children: [textParagraph(text, { alignment: opts.alignment, bold: opts.bold, italics: opts.italics, size: opts.size || 21, color: opts.color })],
  });
}

function screenshotCell(flow) {
  const children = [textParagraph("Screenshot", { alignment: AlignmentType.CENTER, bold: true, italics: true, size: 21 })];
  if (flow.sample && fs.existsSync(sampleImagePath)) {
    children.push(new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 60, after: 60 },
      children: [new ImageRun({ data: fs.readFileSync(sampleImagePath), transformation: { width: 470, height: 333 }, type: "png" })],
    }));
    children.push(textParagraph("Gambar acuan tampilan login dari pengguna.", { alignment: AlignmentType.CENTER, size: 17, italics: true, color: colors.gray }));
  } else {
    children.push(new Paragraph({
      alignment: AlignmentType.CENTER,
      spacing: { before: 80, after: 80 },
      shading: { type: ShadingType.CLEAR, fill: "EDEDED" },
      children: [new TextRun({ text: "Tempat screenshot hasil pengujian aktual", font: "Times New Roman", size: 22, italics: true, color: colors.gray })],
    }));
    children.push(textParagraph("Screenshot aktual dapat ditempel pada area ini setelah pengujian aplikasi.", { alignment: AlignmentType.CENTER, size: 17, italics: true, color: colors.gray }));
  }
  return new TableCell({
    columnSpan: 3,
    margins: { top: 90, bottom: 90, left: 100, right: 100 },
    children,
  });
}

function testTable(flow) {
  const rows = [
    new TableRow({ children: [cell("Tes Faktor", { width: 2600, alignment: AlignmentType.CENTER, bold: true, shading: colors.blue }), cell("Hasil", { width: 1200, alignment: AlignmentType.CENTER, bold: true, shading: colors.blue }), cell("Keterangan", { width: 5200, alignment: AlignmentType.CENTER, bold: true, shading: colors.blue })] }),
  ];
  flow.cases.forEach(([factor, result, note]) => rows.push(new TableRow({ children: [cell(factor, { width: 2600, italics: true }), cell(result, { width: 1200, alignment: AlignmentType.CENTER, size: 30 }), cell(note, { width: 5200 })] })));
  rows.push(new TableRow({ children: [screenshotCell(flow)] }));
  return new Table({
    width: { size: 9000, type: WidthType.DXA },
    columnWidths: [2600, 1200, 5200],
    rows,
    borders: { top: { style: BorderStyle.SINGLE, size: 6, color: colors.border }, bottom: { style: BorderStyle.SINGLE, size: 6, color: colors.border }, left: { style: BorderStyle.SINGLE, size: 6, color: colors.border }, right: { style: BorderStyle.SINGLE, size: 6, color: colors.border }, insideHorizontal: { style: BorderStyle.SINGLE, size: 4, color: colors.border }, insideVertical: { style: BorderStyle.SINGLE, size: 4, color: colors.border } },
  });
}

function flowPathParagraph(flow) {
  return new Paragraph({
    spacing: { before: 100, after: 140, line: 220 },
    children: [
      new TextRun({ text: "Dasar white-box: ", bold: true, font: "Times New Roman", size: 18 }),
      new TextRun({ text: flow.whitebox.join(" → "), font: "Times New Roman", size: 18, color: colors.gray }),
    ],
  });
}

async function main() {
  const children = [];
  children.push(
    new Paragraph({ spacing: { before: 1900 } }),
    textParagraph("PENGUJIAN BLACK BOX", { alignment: AlignmentType.CENTER, bold: true, size: 34, spacing: { after: 180 } }),
    textParagraph("APLIKASI AQUA JAPAN", { alignment: AlignmentType.CENTER, bold: true, size: 30, spacing: { after: 180 } }),
    textParagraph("Sistem Informasi Pemesanan dan Pengiriman Berbasis Mobile & Web", { alignment: AlignmentType.CENTER, italics: true, size: 22, spacing: { after: 700 } }),
    textParagraph("Dokumen pengujian disusun berdasarkan 25 white-box flowchart pada papan Figma/FigJam.", { alignment: AlignmentType.CENTER, size: 20, color: colors.gray, spacing: { after: 120 } }),
    textParagraph("Sumber: https://www.figma.com/board/KGGAqE0V37XHQViYJduqrg/Untitled", { alignment: AlignmentType.CENTER, size: 17, color: colors.gray, spacing: { after: 500 } }),
    textParagraph("Catatan: tanda ✓ menunjukkan hasil yang diharapkan/sesuai rancangan black-box. Screenshot aktual fitur selain login disiapkan sebagai area pengisian bukti uji.", { alignment: AlignmentType.CENTER, size: 18, italics: true, color: colors.gray, spacing: { after: 700 } }),
    new Paragraph({ children: [new PageBreak()] }),
    textParagraph("RINGKASAN PENGUJIAN", { alignment: AlignmentType.CENTER, bold: true, size: 28, spacing: { after: 220 } }),
    textParagraph(`Jumlah fitur: ${flows.length}`, { size: 22, spacing: { after: 80 } }),
    textParagraph(`Jumlah skenario: ${flows.reduce((n, f) => n + f.cases.length, 0)}`, { size: 22, spacing: { after: 80 } }),
    textParagraph("Teknik: black-box equivalence/validity testing berdasarkan alur normal dan cabang gagal pada white-box.", { size: 22, spacing: { after: 160 } }),
  );

  const actorCounts = {};
  for (const f of flows) actorCounts[f.actor] = (actorCounts[f.actor] || 0) + f.cases.length;
  children.push(new Table({
    width: { size: 9000, type: WidthType.DXA },
    columnWidths: [4800, 4200],
    rows: [
      new TableRow({ children: [cell("Aktor", { width: 4800, bold: true, alignment: AlignmentType.CENTER, shading: colors.blue }), cell("Jumlah Skenario", { width: 4200, bold: true, alignment: AlignmentType.CENTER, shading: colors.blue })] }),
      ...Object.entries(actorCounts).map(([actor, count]) => new TableRow({ children: [cell(actor, { width: 4800 }), cell(String(count), { width: 4200, alignment: AlignmentType.CENTER })] })),
    ],
    borders: { top: { style: BorderStyle.SINGLE, size: 6, color: colors.border }, bottom: { style: BorderStyle.SINGLE, size: 6, color: colors.border }, left: { style: BorderStyle.SINGLE, size: 6, color: colors.border }, right: { style: BorderStyle.SINGLE, size: 6, color: colors.border }, insideHorizontal: { style: BorderStyle.SINGLE, size: 4, color: colors.border }, insideVertical: { style: BorderStyle.SINGLE, size: 4, color: colors.border } },
  }));

  for (let i = 0; i < flows.length; i++) {
    const flow = flows[i];
    children.push(new Paragraph({ children: [new PageBreak()] }));
    children.push(textParagraph(`${i + 1}. ${flow.title}`, { alignment: AlignmentType.CENTER, bold: true, size: 27, spacing: { after: 90 } }));
    children.push(textParagraph(`Aktor: ${flow.actor}`, { size: 20, italics: true, color: colors.gray, spacing: { after: 40 } }));
    children.push(flowPathParagraph(flow));
    children.push(testTable(flow));
  }

  if (fs.existsSync(sampleImagePath)) {
    children.push(new Paragraph({ children: [new PageBreak()] }));
    children.push(textParagraph("LAMPIRAN — GAMBAR ACUAN FORMAT", { alignment: AlignmentType.CENTER, bold: true, size: 27, spacing: { after: 200 } }));
    children.push(new Paragraph({ alignment: AlignmentType.CENTER, children: [new ImageRun({ data: fs.readFileSync(sampleImagePath), transformation: { width: 493, height: 349 }, type: "png" })] }));
    children.push(textParagraph("Gambar acuan yang diberikan pengguna.", { alignment: AlignmentType.CENTER, size: 18, italics: true, color: colors.gray }));
  }

  const doc = new Document({
    creator: "Codex",
    title: "Pengujian Black Box Aplikasi AQUA JAPAN",
    description: "Pengujian black-box berdasarkan white-box flowchart pada Figma/FigJam",
    styles: { default: { document: { run: { font: "Times New Roman", size: 22 } } } },
    sections: [{ properties: { page: { margin: { top: 1080, right: 1080, bottom: 1080, left: 1440 } } }, children }],
  });
  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync(outputPath, buffer);
  console.log(`DONE: ${outputPath}`);
  console.log(`Fitur: ${flows.length}`);
  console.log(`Skenario: ${flows.reduce((n, f) => n + f.cases.length, 0)}`);
  console.log(`Ukuran: ${(buffer.length / 1024).toFixed(1)} KB`);
}

main().catch((error) => { console.error(error); process.exitCode = 1; });
