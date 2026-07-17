import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../widgets/smooth_list_item.dart';
import 'store_stock_page.dart';

class CabangDashboardPage extends StatefulWidget {
  const CabangDashboardPage({super.key});

  @override
  State<CabangDashboardPage> createState() => _CabangDashboardPageState();
}

class _CabangDashboardPageState extends State<CabangDashboardPage> {
  bool _loading = true;
  String _error = '';
  int _stokMasuk = 0;
  List<dynamic> _stokTersedia = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final res = await ApiClient.getDashboard();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) setState(() {
          _stokMasuk = data['stok_masuk'] ?? 0;
          _stokTersedia = data['stok_tersedia'] ?? [];
          _loading = false;
        });
      } else {
        if (mounted) setState(() { _error = 'Gagal memuat dashboard (${res.statusCode})'; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Terjadi kesalahan jaringan.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ShimmerBox(width: double.infinity, height: 100, borderRadius: BorderRadius.circular(12)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ShimmerBox(width: double.infinity, height: 80, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 12),
          Expanded(child: ShimmerBox(width: double.infinity, height: 80, borderRadius: BorderRadius.circular(12))),
        ]),
      ],
    );
    if (_error.isNotEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(_error, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        FilledButton(onPressed: _fetch, child: const Text('Coba Lagi')),
      ]));
    }
    final cs = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          color: cs.primaryContainer,
          child: Padding(padding: const EdgeInsets.all(16.0), child: Row(children: [
            Icon(Icons.inventory_2, size: 40, color: cs.onPrimaryContainer),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Total Pengiriman', style: TextStyle(fontSize: 14, color: cs.onPrimaryContainer.withValues(alpha: 0.8))),
              Text('$_stokMasuk', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
            ])),
          ])),
        ),
        const SizedBox(height: 24),
        Card(
          color: cs.secondaryContainer,
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StoreStockPage(stokTersedia: _stokTersedia))),
            borderRadius: BorderRadius.circular(12),
            child: Padding(padding: const EdgeInsets.all(16.0), child: Row(children: [
              Icon(Icons.storefront, size: 40, color: cs.onSecondaryContainer),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Stok Toko', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSecondaryContainer)),
                Text('Lihat ketersediaan stok di toko saat ini', style: TextStyle(fontSize: 14, color: cs.onSecondaryContainer.withValues(alpha: 0.8))),
              ])),
              Icon(Icons.chevron_right, color: cs.onSecondaryContainer),
            ])),
          ),
        ),
      ]),
    );
  }
}
