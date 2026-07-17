import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../widgets/smooth_list_item.dart';

class GudangPackingPage extends StatefulWidget {
  const GudangPackingPage({super.key});

  @override
  State<GudangPackingPage> createState() => _GudangPackingPageState();
}

class _GudangPackingPageState extends State<GudangPackingPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _packingOrderId;
  String? _sendingOrderId;
  String _filter = 'semua';

  @override
  void initState() { super.initState(); _fetch(); }

  void _snack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getGudangOrders();
      if (res.statusCode == 200) {
        _orders = (jsonDecode(res.body)['orders'] as List? ?? []).cast<Map<String, dynamic>>();
      }
    } catch (_) { _snack('Gagal memuat'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'semua') return _orders;
    return _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == _filter).toList();
  }

  String _displayName(Map<String, dynamic> o) {
    final nama = (o['cabang_nama'] ?? '').toString();
    if (nama.isNotEmpty) return nama;
    return (o['cabang_username'] ?? '-').toString();
  }

  void _showDetail(Map<String, dynamic> o) {
    final items = (o['items'] as List? ?? []).cast<Map<String, dynamic>>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (ctx, ctrl) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
              )),
              const SizedBox(height: 12),
              Text(o['kode_order'] ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Cabang: ${_displayName(o)}', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              const Text('Daftar Barang:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: ctrl,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    return ListTile(
                      dense: true,
                      leading: ProductThumb(url: it['gambar_url']?.toString() ?? ''),
                      title: Text(it['nama_produk'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('SKU: ${it['sku'] ?? ''} | ${it['satuan'] ?? ''}'),
                      trailing: Text('x${it['qty'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pack(String id) async {
    final catatan = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Tandai Dikemas'),
          content: TextField(controller: ctrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Catatan packing (opsional)', hintText: 'Contoh: dus karton, segel aman')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Tandai Dikemas')),
          ],
        );
      },
    );
    if (catatan == null) return;

    setState(() => _packingOrderId = id);
    try {
      final res = await ApiClient.packOrder(id, catatan: catatan);
      if (res.statusCode == 200) { _snack('✅ Ditandai dikemas!'); _fetch(); }
      else _snack('Gagal');
    } catch (e) { _snack('Error: $e'); }
    finally { if (mounted) setState(() => _packingOrderId = null); }
  }

  Future<void> _send(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim Barang'),
        content: const Text('Resi pengiriman akan dibuat otomatis. Lanjutkan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Kirim')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _sendingOrderId = id);
    try {
      final res = await ApiClient.sendOrder(id);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final resi = body['kode_pengiriman']?.toString() ?? '';
        _snack('✅ Barang dikirim! Resi: $resi');
        _fetch();
      } else {
        _snack('Gagal mengirim');
      }
    } catch (e) { _snack('Error: $e'); }
    finally { if (mounted) setState(() => _sendingOrderId = null); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading && _orders.isEmpty) return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => const ShimmerCard(),
    );

    return Column(children: [
      // Filter chips
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          for (final f in ['semua', 'approved_admin', 'dipaket', 'dikirim'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f == 'semua' ? 'Semua' : f == 'approved_admin' ? 'Siap Dikemas' : f == 'dipaket' ? 'Dikemas' : 'Dikirim'),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
              ),
            ),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: _filtered.isEmpty
              ? ListView(children: [const SizedBox(height: 80), Center(child: Column(children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12), Text('Tidak ada pesanan', style: TextStyle(color: cs.onSurfaceVariant))]))])
              : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _filtered.length, itemBuilder: (_, i) {
                  final o = _filtered[i];
                  final st = (o['status'] ?? '').toString().toLowerCase();
                  final isReady = st == 'approved_admin';
                  final isPacked = st == 'dipaket';
                  final isSent = st == 'dikirim';

                  return SmoothListItem(index: i, child: Card(margin: const EdgeInsets.only(bottom: 12), child: InkWell(
                    onTap: () => _showDetail(o),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text(o['kode_order'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                          StatusChip(status: st),
                        ]),
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.store, size: 14, color: cs.outline),
                          const SizedBox(width: 4),
                          Text(_displayName(o), style: TextStyle(color: cs.outline, fontSize: 13)),
                        ]),
                        Text('${o['jumlah_item'] ?? 0} item | ${formatCurrency(o['total_harga'] ?? 0)}', style: TextStyle(color: cs.outline)),
                        if (o['keterangan']?.toString().isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 4),
                          child: Text('Catatan: ${o['keterangan']}', style: TextStyle(fontSize: 13, color: cs.outline))),
                        if (o['kode_pengiriman']?.toString().isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 4),
                          child: Row(children: [
                            Icon(Icons.receipt_long, size: 14, color: cs.primary),
                            const SizedBox(width: 4),
                            Text('Resi: ${o['kode_pengiriman']}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary)),
                          ])),
                        if (isSent) Padding(padding: const EdgeInsets.only(top: 4),
                          child: Text('Menunggu konfirmasi cabang...', style: TextStyle(fontSize: 12, color: Colors.orange.shade700, fontStyle: FontStyle.italic))),
                        const SizedBox(height: 12),
                        Row(children: [
                          if (isReady) _actionBtn('Tandai Dikemas', Icons.inventory_2, cs.tertiary, _packingOrderId == o['id'], () => _pack(o['id'])),
                          if (isPacked) _actionBtn('Kirim Barang', Icons.local_shipping, cs.primary, _sendingOrderId == o['id'], () => _send(o['id'])),
                        ]),
                      ]),
                    ),
                  )));
                }),
        ),
      ),
    ]);
  }

  Widget _actionBtn(String label, IconData icon, Color color, bool isLoading, VoidCallback onTap) {
    return Expanded(child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      onPressed: isLoading ? null : onTap,
      icon: isLoading ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth:2, color: Colors.white)) : Icon(icon),
      label: Text(label),
    ));
  }
}
