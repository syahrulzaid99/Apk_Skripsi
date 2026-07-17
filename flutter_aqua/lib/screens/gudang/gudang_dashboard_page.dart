import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../widgets/smooth_list_item.dart';

class GudangDashboardPage extends StatefulWidget {
  const GudangDashboardPage({super.key});

  @override
  State<GudangDashboardPage> createState() => _GudangDashboardPageState();
}

class _GudangDashboardPageState extends State<GudangDashboardPage> {
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentOrders = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final dashRes = await ApiClient.getDashboard();
      if (dashRes.statusCode == 200) {
        final data = jsonDecode(dashRes.body);
        _stats = data['stats'] as Map<String, dynamic>?;
      }

      // Ambil 5 order terbaru untuk ringkasan
      final ordersRes = await ApiClient.getGudangOrders();
      if (ordersRes.statusCode == 200) {
        final all = (jsonDecode(ordersRes.body)['orders'] as List? ?? []).cast<Map<String, dynamic>>();
        _recentOrders = all.take(5).toList();
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [
          Expanded(child: ShimmerBox(width: double.infinity, height: 100, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 12),
          Expanded(child: ShimmerBox(width: double.infinity, height: 100, borderRadius: BorderRadius.circular(12))),
        ]),
        const SizedBox(height: 12),
        ShimmerBox(width: double.infinity, height: 100, borderRadius: BorderRadius.circular(12)),
        const SizedBox(height: 20),
        for (int i = 0; i < 3; i++) ...[
          ShimmerBox(width: double.infinity, height: 60, borderRadius: BorderRadius.circular(12)),
          const SizedBox(height: 8),
        ],
      ],
    );
    final cs = Theme.of(context).colorScheme;
    final readyToPack = _stats?['readyToPack'] ?? 0;
    final packed = _stats?['packed'] ?? 0;
    final sent = _stats?['sent'] ?? 0;

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // Stat cards
        Row(children: [
          Expanded(child: _statCard(Icons.inventory, 'Siap Dikemas', '$readyToPack', Colors.blue, cs)),
          const SizedBox(width: 12),
          Expanded(child: _statCard(Icons.inventory_2, 'Dikemas', '$packed', Colors.orange, cs)),
        ]),
        const SizedBox(height: 12),
        _statCard(Icons.local_shipping, 'Dalam Pengiriman', '$sent', Colors.green, cs, fullWidth: true),
        const SizedBox(height: 20),

        // Recent orders
        if (_recentOrders.isNotEmpty) ...[
          Text('Pesanan Terbaru', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface)),
          const SizedBox(height: 8),
          for (final o in _recentOrders)
            Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: _statusColor(o['status']),
                child: Icon(_statusIcon(o['status']), color: Colors.white, size: 18),
              ),
              title: Text(o['kode_order'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${o['cabang_nama'] ?? o['cabang_username'] ?? '-'} • ${o['jumlah_item'] ?? 0} item',
                style: TextStyle(fontSize: 12, color: cs.outline),
              ),
              trailing: Text(formatCurrency(o['total_harga'] ?? 0), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: cs.primary)),
            )),
        ],
      ]),
    );
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved_admin': return Colors.blue;
      case 'dipaket': return Colors.orange;
      case 'dikirim': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved_admin': return Icons.check_circle;
      case 'dipaket': return Icons.inventory_2;
      case 'dikirim': return Icons.local_shipping;
      default: return Icons.help;
    }
  }

  Widget _statCard(IconData icon, String label, String value, MaterialColor color, ColorScheme cs, {bool fullWidth = false}) {
    final card = Card(color: color.shade50, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
      Icon(icon, size: 32, color: color),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color.shade800)),
        Text(label, style: TextStyle(color: color.shade600)),
      ]),
    ])));
    return fullWidth ? card : card;
  }
}
