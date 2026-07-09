import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import 'cabang_detail_page.dart';

class CabangStockPage extends StatefulWidget {
  const CabangStockPage({super.key});

  @override
  State<CabangStockPage> createState() => _CabangStockPageState();
}

class _CabangStockPageState extends State<CabangStockPage> {
  List<Map<String, dynamic>> _shipments = [];
  bool _loading = false;
  String _filter = 'semua';

  @override
  void initState() { super.initState(); _fetch(); }

  void _snack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getShipments();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _shipments = (data['shipments'] as List? ?? []).cast<Map<String, dynamic>>();
      } else if (res.statusCode == 401) _snack('Sesi habis');
      else _snack('Gagal memuat data');
    } catch (_) { _snack('Gagal terhubung ke server'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'semua') return _shipments;
    return _shipments.where((s) => (s['status'] ?? '').toString().toLowerCase() == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _fetch,
      child: _loading && _shipments.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(children: [
                  for (final f in ['semua', 'dikirim', 'diterima', 'ditolak'])
                    Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
                      label: Text(f[0].toUpperCase() + f.substring(1)),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    )),
                ]),
              ),
              Expanded(child: _filtered.isEmpty
                  ? ListView(children: const [SizedBox(height: 80), Center(child: Column(children: [
                      Icon(Icons.inbox_outlined, size: 64, color: Colors.black26),
                      SizedBox(height: 12), Text('Belum ada pengiriman', style: TextStyle(color: Colors.black45)),
                    ]))])
                  : ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _filtered.length, itemBuilder: (_, i) {
                      final s = _filtered[i];
                      final kode = s['kode_pengiriman'] ?? '-';
                      final status = s['status'] ?? '-';

                      return Card(margin: const EdgeInsets.only(bottom: 10), child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CabangDetailPage(kode: kode))),
                        child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(kode, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15))),
                            StatusChip(status: status),
                          ]),
                          const SizedBox(height: 8),
                          Row(children: [Icon(Icons.storefront, size: 16, color: cs.primary), const SizedBox(width: 6),
                            Text('Dari: ${s['pengirim'] ?? '-'}', style: const TextStyle(fontSize: 13))]),
                          const SizedBox(height: 4),
                          Row(children: [Icon(Icons.inventory_2, size: 16, color: cs.primary), const SizedBox(width: 6),
                            Text('${s['jumlah_item'] ?? 0} item', style: const TextStyle(fontSize: 13)), const Spacer(),
                            Text(formatCurrency(s['total_harga'] ?? 0), style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary))]),
                        ])),
                      ));
                    }),
              ),
            ]),
    );
  }
}
