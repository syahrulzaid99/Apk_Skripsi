import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../widgets/smooth_list_item.dart';

class AdminShipmentsPage extends StatefulWidget {
  const AdminShipmentsPage({super.key});

  @override
  State<AdminShipmentsPage> createState() => _AdminShipmentsPageState();
}

class _AdminShipmentsPageState extends State<AdminShipmentsPage> {
  List<Map<String, dynamic>> _shipments = [];
  bool _loading = true;
  String _filter = 'semua';

  @override
  void initState() { super.initState(); _fetch(); }

  void _snack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getAdminShipments();
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
            Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
              label: Text(f == 'semua' ? 'Semua' : f[0].toUpperCase() + f.substring(1)),
              selected: _filter == f,
              onSelected: (_) => setState(() => _filter = f),
            )),
        ]),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: _filtered.isEmpty
              ? ListView(children: const [SizedBox(height: 80), Center(child: Text('Tidak ada pengiriman'))])
              : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _filtered.length, itemBuilder: (_, i) {
                  final s = _filtered[i];
                  final st = (s['status'] ?? '').toString().toLowerCase();

                  return SmoothListItem(index: i, child: Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(
                    padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                      if (s['keterangan']?.toString().isNotEmpty == true)
                        Padding(padding: const EdgeInsets.only(top: 2), child: Text(s['keterangan'], style: TextStyle(fontSize: 12, color: cs.outline))),
                    ]),
                  )));
                }),
        ),
      ),
    ]);
  }
}
