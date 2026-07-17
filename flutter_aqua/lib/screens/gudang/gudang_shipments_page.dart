import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../widgets/smooth_list_item.dart';

class GudangShipmentsPage extends StatefulWidget {
  const GudangShipmentsPage({super.key});

  @override
  State<GudangShipmentsPage> createState() => _GudangShipmentsPageState();
}

class _GudangShipmentsPageState extends State<GudangShipmentsPage> {
  List<Map<String, dynamic>> _shipments = [];
  bool _loading = true;
  String _filter = 'semua';

  @override
  void initState() { super.initState(); _fetch(); }

  void _snack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getGudangShipments();
      if (res.statusCode == 200) {
        _shipments = (jsonDecode(res.body)['shipments'] as List? ?? []).cast<Map<String, dynamic>>();
      }
    } catch (_) { _snack('Gagal memuat'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'semua') return _shipments;
    return _shipments.where((s) => (s['status'] ?? '').toString().toLowerCase() == _filter).toList();
  }

  void _showDetail(Map<String, dynamic> s) {
    final items = (s['data_barang'] as List? ?? []).cast<Map<String, dynamic>>();
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
              Row(children: [
                Icon(Icons.receipt_long, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(s['kode_pengiriman'] ?? '-', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ]),
              if (s['po_number']?.toString().isNotEmpty == true)
                Text('PO: ${s['po_number']}', style: TextStyle(color: Colors.grey.shade600)),
              Text('Cabang: ${s['penerima_nama'] ?? s['penerima_username'] ?? '-'}', style: TextStyle(color: Colors.grey.shade600)),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading && _shipments.isEmpty) return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => const ShimmerCard(),
    );

    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          for (final f in ['semua', 'dikirim', 'diterima', 'ditolak'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f == 'semua' ? 'Semua' : f[0].toUpperCase() + f.substring(1)),
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
                  Icon(Icons.local_shipping_outlined, size: 64, color: cs.outlineVariant),
                  const SizedBox(height: 12), Text('Tidak ada pengiriman', style: TextStyle(color: cs.onSurfaceVariant))]))])
              : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _filtered.length, itemBuilder: (_, i) {
                  final s = _filtered[i];
                  final st = (s['status'] ?? '').toString().toLowerCase();

                  return SmoothListItem(index: i, child: Card(margin: const EdgeInsets.only(bottom: 12), child: InkWell(
                    onTap: () => _showDetail(s),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Row(children: [
                            Icon(Icons.receipt_long, size: 18, color: cs.primary),
                            const SizedBox(width: 6),
                            Text(s['kode_pengiriman'] ?? '-', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: cs.primary)),
                          ])),
                          StatusChip(status: st),
                        ]),
                        const SizedBox(height: 4),
                        if (s['po_number']?.toString().isNotEmpty == true)
                          Text('PO: ${s['po_number']}', style: TextStyle(fontSize: 13, color: cs.outline)),
                        Row(children: [
                          Icon(Icons.store, size: 14, color: cs.outline),
                          const SizedBox(width: 4),
                          Text(s['penerima_nama'] ?? s['penerima_username'] ?? '-', style: TextStyle(color: cs.outline, fontSize: 13)),
                        ]),
                        Text('${s['jumlah_item'] ?? 0} item | ${formatCurrency(s['total_harga'] ?? 0)}', style: TextStyle(color: cs.outline, fontSize: 13)),
                        if (st == 'diterima' && s['diterima_at'] != null) Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(children: [
                            Icon(Icons.check_circle, size: 14, color: Colors.green),
                            const SizedBox(width: 4),
                            Text('Diterima', style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                        if (st == 'ditolak') Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(children: [
                            Icon(Icons.cancel, size: 14, color: cs.error),
                            const SizedBox(width: 4),
                            Text('Ditolak', style: TextStyle(fontSize: 12, color: cs.error, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ]),
                    ),
                  )));
                }),
        ),
      ),
    ]);
  }
}
