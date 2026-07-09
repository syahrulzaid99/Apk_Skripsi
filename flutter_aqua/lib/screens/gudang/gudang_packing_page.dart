import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';

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
      if (res.statusCode == 200) { _snack('✅ Barang dikirim!'); _fetch(); }
      else _snack('Gagal mengirim');
    } catch (e) { _snack('Error: $e'); }
    finally { if (mounted) setState(() => _sendingOrderId = null); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading && _orders.isEmpty) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _fetch,
      child: _orders.isEmpty
          ? ListView(children: const [SizedBox(height: 80), Center(child: Column(children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: Colors.black26),
              SizedBox(height: 12), Text('Tidak ada pesanan', style: TextStyle(color: Colors.black45))]))])
          : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _orders.length, itemBuilder: (_, i) {
              final o = _orders[i];
              final st = (o['status'] ?? '').toString().toLowerCase();
              final isReady = st == 'approved_admin';
              final isPacked = st == 'dipaket';

              return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(
                padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(o['kode_order'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                    StatusChip(status: st),
                  ]),
                  const SizedBox(height: 6),
                  Text('Cabang: ${o['cabang_username'] ?? '-'}', style: TextStyle(color: cs.outline)),
                  Text('${o['jumlah_item'] ?? 0} item | ${formatCurrency(o['total_harga'] ?? 0)}', style: TextStyle(color: cs.outline)),
                  if (o['keterangan']?.toString().isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: 4),
                    child: Text('Catatan: ${o['keterangan']}', style: TextStyle(fontSize: 13, color: cs.outline))),
                  const SizedBox(height: 12),
                  Row(children: [
                    if (isReady) _actionBtn('Tandai Dikemas', Icons.inventory_2, Colors.orange, _packingOrderId == o['id'], () => _pack(o['id'])),
                    if (isPacked) _actionBtn('Kirim Barang', Icons.local_shipping, Colors.green, _sendingOrderId == o['id'], () => _send(o['id'])),
                  ]),
                ]),
              ));
            }),
    );
  }

  Widget _actionBtn(String label, IconData icon, MaterialColor color, bool isLoading, VoidCallback onTap) {
    return Expanded(child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
      onPressed: isLoading ? null : onTap,
      icon: isLoading ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth:2, color: Colors.white)) : Icon(icon),
      label: Text(label),
    ));
  }
}
