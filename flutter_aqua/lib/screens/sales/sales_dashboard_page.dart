import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';

class SalesDashboardPage extends StatefulWidget {
  const SalesDashboardPage({super.key});

  @override
  State<SalesDashboardPage> createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends State<SalesDashboardPage> {
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
    final cs = Theme.of(context).colorScheme;
    final pending = _stats?['pending'] ?? 0;
    final inProcess = _stats?['approved'] ?? 0;
    final completed = _stats?['rejected'] ?? 0;

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: Colors.orange.shade50, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Icon(Icons.access_time_outlined, size: 40, color: Colors.orange.shade700),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pending', style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
            Text('$pending', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
          ])),
        ]))),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: Card(color: Colors.blue.shade50, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Icon(Icons.sync, size: 32, color: Colors.blue),
            Text('$inProcess', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
            Text('Dalam Proses', style: TextStyle(color: Colors.blue.shade600)),
          ])))),
          const SizedBox(width: 12),
          Expanded(child: Card(color: Colors.green.shade50, child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Icon(Icons.check_circle, size: 32, color: Colors.green),
            Text('$completed', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
            Text('Selesai', style: TextStyle(color: Colors.green.shade600)),
          ])))),
        ]),
      ]),
    );
  }
}
