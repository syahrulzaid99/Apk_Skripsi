import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';

class SalesOrderListPage extends StatefulWidget {
  const SalesOrderListPage({super.key});

  @override
  State<SalesOrderListPage> createState() => _SalesOrderListPageState();
}

class _SalesOrderListPageState extends State<SalesOrderListPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _filter = 'semua';

  @override
  void initState() { super.initState(); _fetch(); }

  void _snack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getSalesOrders();
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());

    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          for (final f in ['semua', 'pending', 'approved_admin', 'dipaket', 'dikirim', 'diterima'])
            Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
              label: Text(f[0].toUpperCase() + f.substring(1).replaceAll('_', ' ')),
              selected: _filter == f,
              onSelected: (_) => setState(() => _filter = f),
            )),
        ]),
      ),
      Expanded(child: RefreshIndicator(
        onRefresh: _fetch,
        child: _filtered.isEmpty
            ? ListView(children: const [SizedBox(height: 80), Center(child: Text('Tidak ada pesanan'))])
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _filtered.length, itemBuilder: (_, i) {
                final o = _filtered[i];
                final st = (o['status'] ?? '').toString().toLowerCase();
                final paid = (o['payment_status'] ?? '').toString().toLowerCase() == 'settlement';

                return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(
                  padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(o['kode_order'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary))),
                      StatusChip(status: st),
                    ]),
                    const SizedBox(height: 4),
                    Row(children: [
                      Text('Cabang: ${o['cabang_username'] ?? '-'}', style: TextStyle(color: cs.outline, fontSize: 13)),
                      const Spacer(),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: paid ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(paid ? 'LUNAS' : 'BELUM BAYAR',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: paid ? Colors.green : Colors.orange))),
                    ]),
                    Text('${o['jumlah_item'] ?? 0} item | ${formatCurrency(o['total_harga'] ?? 0)}', style: TextStyle(color: cs.outline, fontSize: 13)),
                  ]),
                ));
              }),
      )),
    ]);
  }
}
