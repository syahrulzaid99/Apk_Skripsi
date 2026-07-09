import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class GudangDashboardPage extends StatefulWidget {
  const GudangDashboardPage({super.key});

  @override
  State<GudangDashboardPage> createState() => _GudangDashboardPageState();
}

class _GudangDashboardPageState extends State<GudangDashboardPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getDashboard();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _stats = data['stats'] as Map<String, dynamic>?);
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final readyToPack = _stats?['readyToPack'] ?? 0;
    final packed = _stats?['packed'] ?? 0;
    final sent = _stats?['sent'] ?? 0;

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: _card(Icons.inventory, 'Siap Dikemas', '$readyToPack', Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _card(Icons.inventory_2, 'Sedang Dikemas', '$packed', Colors.orange)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _card(Icons.local_shipping, 'Dalam Pengiriman', '$sent', Colors.green)),
        ]),
      ]),
    );
  }

  Widget _card(IconData icon, String label, String value, MaterialColor color) {
    return Card(color: color.shade50, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Icon(icon, size: 32, color: color),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color.shade800)),
      Text(label, style: TextStyle(color: color.shade600)),
    ])));
  }
}
