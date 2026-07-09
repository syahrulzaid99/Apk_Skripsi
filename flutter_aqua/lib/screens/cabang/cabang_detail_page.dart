import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_client.dart';
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
      final res = await ApiClient.confirmShipment(
        kode: widget.kode, aksi: _aksi, keterangan: _keteranganCtrl.text.trim(),
        items: items, photos: _localPhotos,
      );
      if (res.statusCode == 200) { _localPhotos.clear(); _snack('✅ Konfirmasi berhasil!'); await _fetch(); }
      else _snack('Gagal konfirmasi (${res.statusCode})');
    } catch (e) { _snack('Gagal: $e'); }
    finally { if (mounted) setState(() => _busy = false); }
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
      ])),
    );
  }
}
