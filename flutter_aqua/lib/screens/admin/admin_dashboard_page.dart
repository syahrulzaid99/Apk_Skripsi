import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/smooth_list_item.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getAdminDashboard();
      if (res.statusCode == 200) {
        setState(() => _data = jsonDecode(res.body));
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (int i = 0; i < 3; i++) ...[
          ShimmerBox(width: double.infinity, height: 20, borderRadius: BorderRadius.circular(6)),
          const SizedBox(height: 8),
          Wrap(spacing: 12, runSpacing: 12, children: [
            for (int j = 0; j < 3; j++)
              ShimmerBox(width: 90, height: 70, borderRadius: BorderRadius.circular(12)),
          ]),
          const SizedBox(height: 20),
        ],
      ],
    );
    if (_data == null) return Center(child: TextButton(onPressed: _fetch, child: const Text('Gagal memuat. Coba lagi')));

    final orders = _data!['orders'] ?? {};
    final users = _data!['users'] ?? {};
    final products = _data!['products'] ?? {};
    final shipments = _data!['shipments'] ?? {};

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        _sectionTitle('Pesanan', Icons.receipt_long),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _stat('Pending', orders['pending'], Colors.orange),
          _stat('Disetujui', orders['approved'], Colors.blue),
          _stat('Dikemas', orders['dipaket'], Colors.teal),
          _stat('Dikirim', orders['dikirim'], Colors.green),
          _stat('Diterima', orders['diterima'], Colors.purple),
        ]),
        const SizedBox(height: 20),
        _sectionTitle('Pengiriman', Icons.local_shipping),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _stat('Dikirim', shipments['dikirim'], Colors.blue),
          _stat('Diterima', shipments['diterima'], Colors.green),
          _stat('Ditolak', shipments['ditolak'], Colors.red),
        ]),
        const SizedBox(height: 20),
        _sectionTitle('Pengguna', Icons.people),
        const SizedBox(height: 8),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _stat('Admin', users['admin'], Colors.red),
          _stat('Cabang', users['cabang'], Colors.blue),
          _stat('Sales', users['sales'], Colors.green),
          _stat('Gudang', users['gudang'], Colors.orange),
        ]),
        const SizedBox(height: 20),
        _sectionTitle('Produk', Icons.inventory_2),
        const SizedBox(height: 8),
        _stat('Total Produk', products['total'], Colors.indigo),
      ]),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(children: [
      Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _stat(String label, dynamic value, Color color) {
    return Card(
      color: color.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(children: [
          Text('${value ?? 0}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.7))),
        ]),
      ),
    );
  }
}
