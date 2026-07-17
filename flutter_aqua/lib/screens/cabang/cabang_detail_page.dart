import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_client.dart';
import '../../services/location_service.dart';
import '../../widgets/shared.dart';
import '../../config/api_config.dart';

class CabangDetailPage extends StatefulWidget {
  final String kode;
  const CabangDetailPage({super.key, required this.kode});

  @override
  State<CabangDetailPage> createState() => _CabangDetailPageState();
}

class _CabangDetailPageState extends State<CabangDetailPage> {
  Map<String, dynamic>? _data;
  bool _loading = false, _busy = false;
  String _aksi = 'diterima';
  final _keteranganCtrl = TextEditingController();
  final List<TextEditingController> _qtyCtrls = [];
  final List<TextEditingController> _catCtrls = [];
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _localPhotos = [];

  // 📍 Tracking lokasi
  LocationSnapshot? _capturedLocation;
  bool _capturingLoc = false;
  String? _locationError;

  @override
  void initState() { super.initState(); _fetch(); }

  @override
  void dispose() {
    _keteranganCtrl.dispose();
    for (final c in _qtyCtrls) c.dispose();
    for (final c in _catCtrls) c.dispose();
    super.dispose();
  }

  void _snack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  Future<void> _gotoLogin() async {
    // handled by parent
  }

  void _resetItemControllers(int len, List<dynamic> items) {
    for (final c in _qtyCtrls) c.dispose();
    for (final c in _catCtrls) c.dispose();
    _qtyCtrls.clear(); _catCtrls.clear();
    for (int i = 0; i < len; i++) {
      final it = Map<String, dynamic>.from(items[i] as Map);
      final qty = toInt(it['qty'] ?? it['_qty'] ?? it['jumlah'] ?? 0);
      _qtyCtrls.add(TextEditingController(text: qty.toString()));
      _catCtrls.add(TextEditingController(text: ''));
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getShipment(widget.kode);
      if (res.statusCode == 200) {
        final m = jsonDecode(res.body) as Map<String, dynamic>;
        _data = m;
        final items = (m['items'] as List? ?? []);
        if (_qtyCtrls.length != items.length) _resetItemControllers(items.length, items);
        if (mounted) setState(() {});
      } else if (res.statusCode == 403) { _snack('Bukan untuk cabang kamu.'); Navigator.pop(context); }
      else if (res.statusCode == 404) { _snack('Resi tidak ditemukan.'); Navigator.pop(context); }
      else _snack('Gagal (${res.statusCode})');
    } catch (_) { _snack('Gagal terhubung ke server'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  bool _isLocked(Map<String, dynamic> data) {
    final st = (data['status'] ?? '').toString().toLowerCase();
    return st == 'diterima' || st == 'ditolak';
  }

  Future<void> _confirm() async {
    final data = _data;
    if (data == null) { _snack('Data tidak tersedia'); return; }
    if (_isLocked(data)) { _snack('Resi sudah dikonfirmasi'); return; }

    setState(() => _busy = true);
    try {
      final itemsRaw = (data['items'] as List? ?? []);
      final items = <Map<String, dynamic>>[];
      for (int i = 0; i < itemsRaw.length; i++) {
        items.add({'idx': i, 'qty_diterima': int.tryParse(_qtyCtrls[i].text.trim()) ?? 0, 'catatan': _catCtrls[i].text.trim()});
      }

      // 📍 Auto-capture lokasi saat konfirmasi (best-effort; tidak memblokir kirim)
      Map<String, dynamic>? locationPayload;
      if (_capturedLocation == null) {
        final snap = await LocationService.getCurrent();
        if (snap != null) {
          _capturedLocation = snap;
          locationPayload = snap.toMap();
        }
      } else {
        locationPayload = _capturedLocation!.toMap();
      }

      final res = await ApiClient.confirmShipment(
        kode: widget.kode, aksi: _aksi, keterangan: _keteranganCtrl.text.trim(),
        items: items, photos: _localPhotos, location: locationPayload,
      );
      if (res.statusCode == 200) {
        _localPhotos.clear();
        _snack(locationPayload != null
            ? '✅ Konfirmasi berhasil (lokasi tercatat)'
            : '✅ Konfirmasi berhasil (lokasi tidak tersedia)');
        await _fetch();
      } else {
        String msg = 'Gagal konfirmasi (${res.statusCode})';
        try {
          final raw = await res.stream.bytesToString();
          final body = jsonDecode(raw) as Map<String, dynamic>;
          if (body['error'] == 'location_accuracy_too_low') {
            msg = body['message']?.toString() ?? msg;
          }
        } catch (_) {}
        _snack(msg);
      }
    } catch (e) { _snack('Gagal: $e'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  // 📍 Ambil lokasi saat ini secara manual (dipakai tombol "Ambil Lokasi")
  Future<void> _captureLocation() async {
    setState(() {
      _capturingLoc = true;
      _locationError = null;
    });
    final snap = await LocationService.getCurrent();
    if (!mounted) return;
    if (snap == null) {
      setState(() {
        _capturingLoc = false;
        _locationError = 'Lokasi tidak tersedia. Pastikan GPS aktif & izin diberikan.';
      });
      return;
    }
    setState(() {
      _capturedLocation = snap;
      _capturingLoc = false;
    });
    _snack('📍 Lokasi berhasil dicapture');
  }

  Future<void> _openMap(double lat, double lng) async {
    final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng(Lokasi Konfirmasi)');
    final web = Uri.parse('https://www.google.com/maps?q=$lat,$lng');
    try {
      if (await canLaunchUrl(geo)) {
        await launchUrl(geo, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(web, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  Widget _locationCard({required bool locked}) {
    final cs = Theme.of(context).colorScheme;
    // Ambil snapshot lokasi dari data response (jika sudah pernah dikonfirmasi)
    final data = _data;
    final serverLoc = data != null
        ? (Map<String, dynamic>.from(
            (data[_aksi == 'ditolak' ? 'lokasi_penolakan' : 'lokasi_penerimaan']) is Map
                ? (data[_aksi == 'ditolak' ? 'lokasi_penolakan' : 'lokasi_penerimaan']) as Map
                : const {}))
        : const <String, dynamic>{};
    final hasServer = serverLoc.isNotEmpty &&
        serverLoc['lat'] != null &&
        serverLoc['lng'] != null;

    final showServer = locked && hasServer;
    final showClient = !locked && _capturedLocation != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.redAccent),
                const SizedBox(width: 8),
                const Text('Tracking Lokasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const Spacer(),
                if (locked && hasServer)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text('Tercatat',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.green.shade700)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (showServer) ...[
              _locationRow('Koordinat',
                  '${serverLoc['lat']}, ${serverLoc['lng']}'),
              if ((serverLoc['accuracy'] as num?) != null)
                _locationRow('Akurasi', '±${serverLoc['accuracy'].toStringAsFixed(0)} m'),
              if (serverLoc['address'] != null &&
                  (serverLoc['address'] as String).isNotEmpty)
                _locationRow('Alamat', serverLoc['address'].toString()),
              if (serverLoc['captured_at'] != null)
                _locationRow('Waktu', serverLoc['captured_at'].toString()),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  final lat = (serverLoc['lat'] as num).toDouble();
                  final lng = (serverLoc['lng'] as num).toDouble();
                  _openMap(lat, lng);
                },
                icon: const Icon(Icons.map),
                label: const Text('Buka di Maps'),
              ),
            ] else if (showClient) ...[
              _locationRow('Koordinat', _capturedLocation!.latLngLabel),
              if (_capturedLocation!.accuracy != null)
                _locationRow('Akurasi', '±${_capturedLocation!.accuracy!.toStringAsFixed(0)} m'),
              if (_capturedLocation!.address != null &&
                  _capturedLocation!.address!.isNotEmpty)
                _locationRow('Alamat', _capturedLocation!.address!),
              const SizedBox(height: 6),
              Text(
                'Lokasi akan otomatis ikut terkirim saat konfirmasi.',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _capturingLoc ? null : _captureLocation,
                    icon: _capturingLoc
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
                    label: Text(_capturingLoc ? 'Mengambil...' : 'Ambil Ulang'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      _openMap(_capturedLocation!.latitude,
                          _capturedLocation!.longitude);
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Lihat di Maps'),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Belum ada lokasi. Ambil lokasi saat ini untuk dicatat di bukti '
                'penerimaan/penolakan.',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              if (_locationError != null) ...[
                const SizedBox(height: 6),
                Text(_locationError!,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.redAccent)),
              ],
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: _capturingLoc ? null : _captureLocation,
                icon: _capturingLoc
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location),
                label: Text(_capturingLoc ? 'Mengambil lokasi...' : 'Ambil Lokasi Saat Ini'),
              ),
              const SizedBox(height: 4),
              Text(
                'Lokasi juga otomatis dicapture saat tombol Konfirmasi ditekan.',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _locationRow(String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (_loading && data == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (data == null) return Scaffold(appBar: AppBar(title: Text(widget.kode)), body: const Center(child: Text('Data tidak tersedia')));

    final locked = _isLocked(data);
    final items = (data['items'] as List? ?? []);
    final alamatJalan = (data['alamat_penerima_jalan'] ?? '').toString();
    final alamatKota = (data['alamat_penerima_kota'] ?? '').toString();
    final alamatProv = (data['alamat_penerima_provinsi'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: Text(data['kode_pengiriman']?.toString() ?? widget.kode), actions: [IconButton(onPressed: _loading ? null : _fetch, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(onRefresh: _fetch, child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(data['kode_pengiriman']?.toString() ?? widget.kode, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))), StatusChip(status: data['status'] ?? '-')]),
          const SizedBox(height: 10),
          InfoRow(icon: Icons.storefront, label: 'Pengirim', value: (data['pengirim'] ?? '-').toString()),
          const SizedBox(height: 6),
          InfoRow(icon: Icons.home_work, label: 'Penerima', value: (data['penerima'] ?? '-').toString()),
          const SizedBox(height: 10),
          const Divider(),
          InfoRow(icon: Icons.monetization_on, label: 'Total', value: formatCurrency(data['total_harga'] ?? 0)),
          const SizedBox(height: 10),
          const Divider(),
          const Text('Alamat Penerima', style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.location_on), const SizedBox(width: 8),
            Expanded(child: Text([if (alamatJalan.isNotEmpty) alamatJalan, [if (alamatKota.isNotEmpty) alamatKota, if (alamatProv.isNotEmpty) alamatProv].join(', ')].where((e) => e.toString().trim().isNotEmpty).join('\n'))),
          ]),
        ]))),
        const SizedBox(height: 14),
        const Text('Daftar Barang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((e) {
          final it = Map<String, dynamic>.from(e.value as Map);
          final nama = (it['nama_produk'] ?? '-').toString();
          final qty = toInt(it['qty'] ?? it['_qty'] ?? it['jumlah'] ?? 0);
          final harga = it['harga'] ?? 0;
          return Card(margin: const EdgeInsets.only(bottom: 10), child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            leading: ProductThumb(url: (it['gambar_url'] ?? it['imageUrl'] ?? it['image_url'])?.toString() ?? ''),
            title: Text(nama, style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text('SKU: ${it['sku'] ?? ''}\nHarga: ${formatCurrency(harga)}'),
            trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: Theme.of(context).colorScheme.primaryContainer),
              child: Text('Qty\n$qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.onPrimaryContainer))),
          ));
        }),
        // Confirm section
        Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Konfirmasi Penerimaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          Wrap(spacing: 10, children: [
            ChoiceChip(label: const Text('Diterima'), selected: _aksi == 'diterima', onSelected: locked ? null : (_) => setState(() => _aksi = 'diterima')),
            ChoiceChip(label: const Text('Ditolak'), selected: _aksi == 'ditolak', onSelected: locked ? null : (_) => setState(() => _aksi = 'ditolak')),
          ]),
          const SizedBox(height: 10),
          TextField(controller: _keteranganCtrl, enabled: !locked, maxLines: 3, decoration: const InputDecoration(labelText: 'Keterangan', hintText: 'Kondisi umum, dll.')),
          const SizedBox(height: 12),
          FilledButton.icon(onPressed: locked || _busy ? null : _confirm,
            icon: _busy ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.verified),
            label: Text(locked ? 'Sudah Dikonfirmasi' : 'Konfirmasi')),
        ]))),
        const SizedBox(height: 14),
        // 📍 Tracking lokasi
        _locationCard(locked: locked),
      ])),
    );
  }
}
