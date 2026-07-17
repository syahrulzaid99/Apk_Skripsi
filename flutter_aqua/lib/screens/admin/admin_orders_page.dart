import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../widgets/smooth_list_item.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _filterStatus = 'semua';
  String? _filterKota;

  @override
  void initState() { super.initState(); _fetch(); }

  void _snack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getAdminOrders();
      if (res.statusCode == 200) {
        _orders = (jsonDecode(res.body)['orders'] as List? ?? []).cast<Map<String, dynamic>>();
      }
    } catch (_) { _snack('Gagal memuat'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  List<String> get _kotaList {
    final seen = <String>{};
    final list = <String>[];
    for (final o in _orders) {
      final k = (o['cabang_kota'] ?? '').toString().trim();
      if (k.isNotEmpty && !seen.contains(k)) { seen.add(k); list.add(k); }
    }
    list.sort();
    return list;
  }

  List<Map<String, dynamic>> get _filtered {
    return _orders.where((o) {
      final st = (o['status'] ?? '').toString().toLowerCase();
      final matchStatus = _filterStatus == 'semua' || st == _filterStatus;
      final matchKota = _filterKota == null || (o['cabang_kota'] ?? '').toString() == _filterKota;
      return matchStatus && matchKota;
    }).toList();
  }

  Future<void> _approve(Map<String, dynamic> o) async {
    final ket = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Setujui Pesanan'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Pesanan: ${o['kode_order']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Cabang: ${o['cabang_nama'] ?? o['cabang_username'] ?? '-'}'),
            Text('Total: ${formatCurrency(o['total_harga'] ?? 0)}'),
            const SizedBox(height: 12),
            TextField(controller: ctrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Keterangan (opsional)')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Setujui')),
          ],
        );
      },
    );
    if (ket == null) return;

    try {
      final res = await ApiClient.adminApproveOrder(o['id'], keterangan: ket);
      if (res.statusCode == 200) { _snack('✅ Pesanan disetujui'); _fetch(); }
      else { final body = jsonDecode(res.body); _snack(body['message'] ?? 'Gagal (${res.statusCode})'); }
    } catch (e) { _snack('Error: $e'); }
  }

  Future<void> _delete(Map<String, dynamic> o) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Pesanan'),
        content: Text('Yakin hapus pesanan ${o['kode_order']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final res = await ApiClient.adminDeleteOrder(o['id']);
      if (res.statusCode == 200) { _snack('🗑️ Pesanan dihapus'); _fetch(); }
      else _snack('Gagal menghapus');
    } catch (e) { _snack('Error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          for (final f in ['semua', 'pending', 'approved_admin', 'dipaket', 'dikirim', 'diterima'])
            Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(
              label: Text(f == 'semua' ? 'Semua' : f[0].toUpperCase() + f.substring(1).replaceAll('_', ' ')),
              selected: _filterStatus == f,
              onSelected: (_) => setState(() => _filterStatus = f),
            )),
        ]),
      ),
      if (_kotaList.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: DropdownButtonFormField<String?>(
            value: _filterKota,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Filter Kota', isDense: true, prefixIcon: Icon(Icons.location_city)),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Semua Kota')),
              ..._kotaList.map((k) => DropdownMenuItem<String?>(value: k, child: Text(k))),
            ],
            onChanged: (v) => setState(() => _filterKota = v),
          ),
        ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: _loading
              ? ListView.builder(padding: const EdgeInsets.all(16), itemCount: 5, itemBuilder: (_, __) => const ShimmerCard())
              : _filtered.isEmpty
                  ? ListView(children: [SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                      Icon(Icons.receipt_long_outlined, size: 64, color: cs.outlineVariant),
                      const SizedBox(height: 12),
                      const Center(child: Text('Tidak ada pesanan'))])
                  : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _filtered.length, itemBuilder: (_, i) {
                      final o = _filtered[i];
                      final st = (o['status'] ?? '').toString().toLowerCase();
                      final paid = (o['payment_status'] ?? '').toString().toLowerCase() == 'settlement';
                      final canApprove = st == 'pending' && paid;
                      final kota = (o['cabang_kota'] ?? '').toString();

                      return SmoothListItem(index: i, child: Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(
                        padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(o['kode_order'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary))),
                            StatusChip(status: st),
                          ]),
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.store, size: 14, color: cs.outline),
                            const SizedBox(width: 4),
                            Expanded(child: Text('${o['cabang_nama'] ?? o['cabang_username'] ?? '-'}', style: TextStyle(color: cs.outline, fontSize: 13))),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: paid ? Colors.green.shade50 : Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                              child: Text(paid ? 'LUNAS' : 'BELUM BAYAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: paid ? Colors.green : Colors.orange))),
                          ]),
                          if (kota.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Row(children: [
                            Icon(Icons.location_on, size: 14, color: cs.outline),
                            const SizedBox(width: 4),
                            Text(kota, style: TextStyle(color: cs.outline, fontSize: 12)),
                          ])),
                          Text('${o['jumlah_item'] ?? 0} item | ${formatCurrency(o['total_harga'] ?? 0)}', style: TextStyle(color: cs.outline, fontSize: 13)),
                          if (o['keterangan']?.toString().isNotEmpty == true)
                            Text('Catatan: ${o['keterangan']}', style: TextStyle(fontSize: 12, color: cs.outline)),
                          if (o['created_by_role'] == 'sales')
                            Padding(padding: const EdgeInsets.only(top: 2), child: Text('Dibuat oleh: Sales', style: TextStyle(fontSize: 11, color: Colors.blue.shade600, fontStyle: FontStyle.italic))),
                          const SizedBox(height: 8),
                          Row(children: [
                            if (canApprove) Expanded(child: OutlinedButton.icon(
                              onPressed: () => _approve(o),
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Setujui'),
                            )),
                            if (canApprove) const SizedBox(width: 8),
                            IconButton(onPressed: () => _delete(o), icon: Icon(Icons.delete_outline, color: cs.error), tooltip: 'Hapus'),
                          ]),
                        ]),
                      )));
                    }),
        ),
      ),
    ]);
  }
}
