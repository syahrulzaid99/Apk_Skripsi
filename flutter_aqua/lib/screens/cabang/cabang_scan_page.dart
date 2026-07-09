import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'cabang_detail_page.dart';

class CabangScanPage extends StatefulWidget {
  const CabangScanPage({super.key});

  @override
  State<CabangScanPage> createState() => _CabangScanPageState();
}

class _CabangScanPageState extends State<CabangScanPage> {
  bool _handled = false;
  final _manual = TextEditingController();

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  void _openDetail(String kode) {
    final k = kode.trim();
    if (k.isEmpty) return;
    Navigator.of(context)
        .push(MaterialPageRoute(
            builder: (_) => CabangDetailPage(kode: k)))
        .then((_) => setState(() => _handled = false));
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null || code.trim().isEmpty) return;
    setState(() => _handled = true);
    _openDetail(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Resi',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(children: [
          // Scanner area
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SizedBox(
              height: 360,
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: MobileScanner(onDetect: _onDetect),
                ),
                // Scan overlay
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2),
                    ),
                    child: Center(
                      child: Container(
                        width: 220,
                        height: 160,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.cyanAccent, width: 2.5),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent
                                  .withValues(alpha: 0.15),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          // Hint text
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner,
                    size: 18, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                Text(
                  'Arahkan kamera ke barcode resi',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14),
                ),
              ],
            ),
          ),
          // Divider
          Row(children: [
            Expanded(
                child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.15))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('atau input manual',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12)),
            ),
            Expanded(
                child: Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.15))),
          ]),
          const SizedBox(height: 20),
          // Manual input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: const Color(0xFF1A1A2E),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: _manual,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Kode Resi',
                        hintText: 'TRXID...',
                        labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5)),
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.25)),
                        prefixIcon: Icon(Icons.qr_code_2,
                            color: Colors.cyanAccent.withValues(alpha: 0.7)),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _openDetail,
                    ),
                  ),
                  FilledButton(
                    onPressed: () => _openDetail(_manual.text),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                    ),
                    child: const Text('Cari',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
