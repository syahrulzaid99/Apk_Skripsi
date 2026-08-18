const {
  Document,
  Packer,
  Paragraph,
  TextRun,
  AlignmentType,
  BorderStyle,
  SectionType,
} = require('docx');
const fs = require('fs');
const path = require('path');

// Margin 4-4-3-3 cm: atas, kiri, bawah, kanan.
const TWIPS_PER_CM = 567;
const MARGINS = {
  top: 4 * TWIPS_PER_CM,
  left: 4 * TWIPS_PER_CM,
  bottom: 3 * TWIPS_PER_CM,
  right: 3 * TWIPS_PER_CM,
};

const FONT = 'Times New Roman';
const CODE_SIZE = 24; // 12 pt dalam satuan half-point milik docx.
const ROOT = __dirname;
const OUTPUT = path.join(ROOT, 'Lampiran_Listing_Program.docx');

// Hanya bagian penting yang ditampilkan; bagian lain dari file diberi penanda.
const sections = [
  {
    title: 'A. APLIKASI MOBILE (FLUTTER)',
    files: [
      { label: 'Inisialisasi aplikasi', path: 'flutter_aqua/lib/main.dart' },
      { label: 'Konfigurasi alamat API', path: 'flutter_aqua/lib/config/api_config.dart' },
      { label: 'Penyimpanan autentikasi', path: 'flutter_aqua/lib/services/auth_service.dart' },
      {
        label: 'Klien API: login, pengiriman, dan pesanan',
        path: 'flutter_aqua/lib/services/api_client.dart',
        ranges: [[1, 46], [48, 90], [106, 119]],
      },
      { label: 'Routing berdasarkan role pengguna', path: 'flutter_aqua/lib/screens/auth/auth_gate.dart' },
    ],
  },
  {
    title: 'B. BACKEND SERVER (NODE.JS)',
    files: [
      { label: 'Konfigurasi Express dan route utama', path: 'web_aqua/src/app.js' },
      { label: 'Inisialisasi Firebase Admin dan Firestore', path: 'web_aqua/src/firebaseAdmin.js' },
      { label: 'Middleware JWT dan pembatasan role', path: 'web_aqua/src/middleware/auth.js', ranges: [[1, 58]] },
      {
        label: 'Autentikasi web dan API',
        path: 'web_aqua/src/routes/auth.route.js',
        ranges: [[1, 8], [11, 13], [64, 130]],
      },
      {
        label: 'Manajemen produk dan upload gambar',
        path: 'web_aqua/src/routes/products.route.js',
        ranges: [[1, 94]],
      },
      {
        label: 'Pembuatan pesanan cabang',
        path: 'web_aqua/src/routes/cabang_orders.route.js',
        ranges: [[57, 134]],
      },
      {
        label: 'Pembuatan pengiriman dan pengurangan stok',
        path: 'web_aqua/src/routes/shipments.route.js',
        ranges: [[19, 35], [91, 171]],
      },
      {
        label: 'Konfirmasi penerimaan pengiriman cabang',
        path: 'web_aqua/src/routes/cabang/shipments.route.js',
        ranges: [[14, 22], [130, 217]],
      },
      { label: 'Pembentukan kode pesanan dan resi', path: 'web_aqua/src/utils/generateCode.js' },
    ],
  },
];

function readListing(file) {
  const absolutePath = path.join(ROOT, file.path);
  const source = fs.readFileSync(absolutePath, 'utf8').replace(/\r\n/g, '\n');
  const lines = source.split('\n');

  if (!file.ranges) return lines;

  const selected = [];
  file.ranges.forEach(([start, end], index) => {
    if (index > 0) {
      selected.push('// ... bagian kode lain tidak ditampilkan ...');
    }
    selected.push(...lines.slice(start - 1, end));
  });
  return selected;
}

function lineParagraphs(lines) {
  return lines.map((line, index) => {
    const number = `${index + 1}.`.padEnd(5, ' ');
    const content = line.replace(/\t/g, '    ').replace(/\r/g, '') || ' ';
    return new Paragraph({
      children: [
        new TextRun({ text: number, font: FONT, size: CODE_SIZE, color: '777777' }),
        new TextRun({ text: content, font: FONT, size: CODE_SIZE, color: '000000' }),
      ],
      spacing: { before: 0, after: 0, line: 240 },
    });
  });
}

function heading(text, size = 28, options = {}) {
  return new Paragraph({
    children: [new TextRun({ text, bold: true, font: FONT, size })],
    spacing: { before: 240, after: 120 },
    ...options,
  });
}

function listingTitle(number, file) {
  return new Paragraph({
    children: [
      new TextRun({ text: `${number}. ${file.label}`, bold: true, font: FONT, size: 26 }),
    ],
    spacing: { before: 220, after: 60 },
    keepNext: true,
  });
}

function pathLine(file) {
  return new Paragraph({
    children: [
      new TextRun({ text: `Sumber: ${file.path}`, italics: true, font: FONT, size: 20, color: '666666' }),
    ],
    spacing: { after: 80 },
    keepNext: true,
  });
}

function buildContents() {
  const children = [
    new Paragraph({ spacing: { before: 900 } }),
    new Paragraph({
      children: [new TextRun({ text: 'LAMPIRAN', bold: true, font: FONT, size: 36 })],
      alignment: AlignmentType.CENTER,
      spacing: { after: 120 },
    }),
    new Paragraph({
      children: [new TextRun({ text: 'LISTING PROGRAM', bold: true, font: FONT, size: 30 })],
      alignment: AlignmentType.CENTER,
      spacing: { after: 100 },
    }),
    new Paragraph({
      children: [new TextRun({ text: 'Aplikasi AQUA JAPAN', italics: true, font: FONT, size: 24 })],
      alignment: AlignmentType.CENTER,
      spacing: { after: 600 },
    }),
    new Paragraph({
      children: [new TextRun({ text: 'DAFTAR LISTING KODE PROGRAM', bold: true, font: FONT, size: 26 })],
      alignment: AlignmentType.CENTER,
      spacing: { after: 260 },
    }),
  ];

  let number = 1;
  sections.forEach((section) => {
    children.push(heading(section.title, 24));
    section.files.forEach((file) => {
      children.push(new Paragraph({
        children: [new TextRun({ text: `${number}. ${file.label}`, font: FONT, size: 24 })],
        spacing: { after: 50 },
      }));
      number += 1;
    });
  });

  return children;
}

function buildCodeListings() {
  const children = [
    heading('LAMPIRAN KODE PROGRAM', 30, {
      alignment: AlignmentType.CENTER,
      border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: '000000' } },
      spacing: { before: 0, after: 220 },
    }),
  ];

  let number = 1;
  sections.forEach((section) => {
    children.push(heading(section.title, 26));
    section.files.forEach((file) => {
      const lines = readListing(file);
      children.push(listingTitle(number, file), pathLine(file), ...lineParagraphs(lines));
      children.push(new Paragraph({ spacing: { after: 100 } }));
      number += 1;
    });
  });
  return children;
}

async function main() {
  const doc = new Document({
    creator: 'Lampiran Skripsi Generator',
    title: 'Lampiran Listing Program - AQUA JAPAN',
    description: 'Listing kode program inti aplikasi AQUA JAPAN',
    styles: {
      default: {
        document: {
          run: { font: FONT, size: CODE_SIZE },
          paragraph: { spacing: { after: 0, line: 240 } },
        },
      },
    },
    sections: [
      {
        properties: { page: { margin: MARGINS } },
        children: buildContents(),
      },
      {
        properties: {
          type: SectionType.NEXT_PAGE,
          page: { margin: MARGINS },
          column: { count: 2, equalWidth: true, space: 360, separate: false },
        },
        children: buildCodeListings(),
      },
    ],
  });

  const buffer = await Packer.toBuffer(doc);
  fs.writeFileSync(OUTPUT, buffer);
  console.log('DONE');
  console.log(`File: ${OUTPUT}`);
  console.log(`Total listing: ${sections.reduce((sum, section) => sum + section.files.length, 0)}`);
  console.log(`Ukuran: ${(buffer.length / 1024 / 1024).toFixed(2)} MB`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
