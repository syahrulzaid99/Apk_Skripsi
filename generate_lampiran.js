const { Document, Packer, Paragraph, TextRun, HeadingLevel, AlignmentType, BorderStyle, PageBreak } = require("docx");
const fs = require("fs");
const path = require("path");

// =============================================
// FILE INTI SAJA - UNTUK SEMINAR HASIL SKRIPSI
// =============================================
const sections = [
  {
    title: "APLIKASI MOBILE (Flutter)",
    files: [
      { label: "main.dart", path: "flutter_aqua/lib/main.dart" },
      { label: "pubspec.yaml", path: "flutter_aqua/pubspec.yaml" },
    ],
  },
  {
    title: "BACKEND SERVER (Node.js)",
    files: [
      { label: "app.js", path: "web_aqua/src/app.js" },
      { label: "firebaseAdmin.js", path: "web_aqua/src/firebaseAdmin.js" },
    ],
  },
  {
    title: "AUTENTIKASI",
    files: [
      { label: "auth.route.js", path: "web_aqua/src/routes/auth.route.js" },
      { label: "auth.js (middleware)", path: "web_aqua/src/middleware/auth.js" },
    ],
  },
  {
    title: "FITUR UTAMA (Routes)",
    files: [
      { label: "products.route.js", path: "web_aqua/src/routes/products.route.js" },
      { label: "admin_orders.route.js", path: "web_aqua/src/routes/admin_orders.route.js" },
      { label: "cabang_orders.route.js", path: "web_aqua/src/routes/cabang_orders.route.js" },
      { label: "shipments.route.js", path: "web_aqua/src/routes/shipments.route.js" },
      { label: "cabang/shipments.route.js", path: "web_aqua/src/routes/cabang/shipments.route.js" },
    ],
  },
];

function createCodeParagraphs(code) {
  const lines = code.split("\n");
  const paragraphs = [];
  for (let i = 0; i < lines.length; i++) {
    const lineNum = String(i + 1).padStart(4, " ");
    const lineContent = lines[i].replace(/\t/g, "    ").replace(/\r/g, "");
    paragraphs.push(
      new Paragraph({
        children: [
          new TextRun({ text: lineNum + " | ", font: "Consolas", size: 16, color: "888888" }),
          new TextRun({ text: lineContent || " ", font: "Consolas", size: 16, color: "000000" }),
        ],
        spacing: { after: 0, before: 0, line: 240 },
      })
    );
  }
  return paragraphs;
}

async function main() {
  const basePath = "d:\\Apk_Skripsi";
  const allChildren = [];

  // ===== HALAMAN JUDUL =====
  allChildren.push(
    new Paragraph({ spacing: { before: 2400 } }),
    new Paragraph({
      children: [new TextRun({ text: "LAMPIRAN", bold: true, size: 56, font: "Times New Roman" })],
      alignment: AlignmentType.CENTER,
      spacing: { after: 400 },
    }),
    new Paragraph({
      children: [new TextRun({ text: "LISTING PROGRAM", bold: true, size: 48, font: "Times New Roman" })],
      alignment: AlignmentType.CENTER,
      spacing: { after: 600 },
    }),
    new Paragraph({
      children: [new TextRun({ text: "Aplikasi AQUA JAPAN", size: 32, font: "Times New Roman", italics: true })],
      alignment: AlignmentType.CENTER,
      spacing: { after: 200 },
    }),
    new Paragraph({
      children: [new TextRun({ text: "Sistem Informasi Pemesanan dan Pengiriman Berbasis Mobile & Web", size: 24, font: "Times New Roman" })],
      alignment: AlignmentType.CENTER,
      spacing: { after: 1200 },
    })
  );

  // ===== DAFTAR ISI =====
  allChildren.push(
    new Paragraph({ children: [new PageBreak()] }),
    new Paragraph({
      children: [new TextRun({ text: "DAFTAR ISI LAMPIRAN KODE PROGRAM", bold: true, size: 28, font: "Times New Roman" })],
      alignment: AlignmentType.CENTER,
      spacing: { after: 400 },
    })
  );

  let counter = 1;
  for (const sec of sections) {
    allChildren.push(
      new Paragraph({
        children: [new TextRun({ text: sec.title, bold: true, size: 22, font: "Times New Roman" })],
        spacing: { before: 200, after: 100 },
      })
    );
    for (const f of sec.files) {
      allChildren.push(
        new Paragraph({
          children: [new TextRun({ text: "    " + counter + ". " + f.label, size: 22, font: "Times New Roman" })],
          spacing: { after: 40 },
        })
      );
      counter++;
    }
  }

  // ===== KONTEN KODE =====
  counter = 1;
  for (const sec of sections) {
    allChildren.push(
      new Paragraph({ children: [new PageBreak()] }),
      new Paragraph({
        children: [new TextRun({ text: sec.title, bold: true, size: 32, font: "Times New Roman", color: "1a1a2e" })],
        alignment: AlignmentType.CENTER,
        spacing: { after: 400 },
        border: { bottom: { style: BorderStyle.SINGLE, size: 6, color: "1a1a2e" } },
      })
    );

    for (const f of sec.files) {
      const filePath = path.join(basePath, f.path);
      let code = "";
      try {
        code = fs.readFileSync(filePath, "utf-8");
      } catch (e) {
        code = "// ERROR: File tidak ditemukan - " + filePath;
        console.warn("File tidak ditemukan: " + filePath);
      }

      const lineCount = code.split("\n").length;

      allChildren.push(
        new Paragraph({
          children: [new TextRun({ text: counter + ". " + f.label, bold: true, size: 24, font: "Times New Roman" })],
          spacing: { before: 400, after: 60 },
        }),
        new Paragraph({
          children: [new TextRun({ text: "Path: " + f.path, size: 18, font: "Consolas", color: "666666", italics: true })],
          spacing: { after: 60 },
        }),
        new Paragraph({
          children: [new TextRun({ text: "Jumlah baris: " + lineCount, size: 18, font: "Consolas", color: "666666", italics: true })],
          spacing: { after: 120 },
        }),
        new Paragraph({
          border: { top: { style: BorderStyle.SINGLE, size: 1, color: "cccccc" } },
          spacing: { after: 60 },
        })
      );

      const codeParagraphs = createCodeParagraphs(code);
      allChildren.push(...codeParagraphs);

      allChildren.push(
        new Paragraph({
          border: { bottom: { style: BorderStyle.SINGLE, size: 1, color: "cccccc" } },
          spacing: { before: 60, after: 200 },
        })
      );
      counter++;
    }
  }

  // ===== BUAT DOKUMEN =====
  const doc = new Document({
    creator: "Lampiran Skripsi Generator",
    title: "Lampiran Listing Program - AQUA JAPAN",
    description: "Lampiran kode program inti untuk seminar hasil skripsi",
    sections: [
      {
        properties: {
          page: {
            margin: { top: 1440, right: 1080, bottom: 1440, left: 1440 },
          },
        },
        children: allChildren,
      },
    ],
  });

  const buffer = await Packer.toBuffer(doc);
  const outputPath = path.join(basePath, "Lampiran_Listing_Program.docx");
  fs.writeFileSync(outputPath, buffer);

  let totalLines = 0;
  let totalFiles = 0;
  for (const sec of sections) {
    for (const f of sec.files) {
      try {
        const code = fs.readFileSync(path.join(basePath, f.path), "utf-8");
        totalLines += code.split("\n").length;
        totalFiles++;
      } catch (e) {}
    }
  }

  console.log("DONE");
  console.log("File: " + outputPath);
  console.log("Total file kode: " + totalFiles);
  console.log("Total baris: " + totalLines);
  console.log("Ukuran: " + (buffer.length / 1024 / 1024).toFixed(2) + " MB");
}

main().catch(console.error);
