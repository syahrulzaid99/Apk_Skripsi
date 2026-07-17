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
  List<Map<String, dynamic>> _recentSales = [];
  List<Map<String, dynamic>> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = ''; });
    try {
      final results = await Future.wait([
        ApiClient.getDashboard(),
        ApiClient.getSales(),
        ApiClient.getOrders(),
      ]);

      final dashRes = results[0];
      final salesRes = results[1];
      final ordersRes = results[2];

      if (dashRes.statusCode == 200) {
        final data = jsonDecode(dashRes.body);
        _stokMasuk = data['stok_masuk'] ?? 0;
        _stokTersedia = data['stok_tersedia'] ?? [];
      }

      if (salesRes.statusCode == 200) {
        _recentSales = (jsonDecode(salesRes.body)['sales'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .take(5)
            .toList();
      }

      if (ordersRes.statusCode == 200) {
        _recentOrders = (jsonDecode(ordersRes.body)['orders'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .take(5)
            .toList();
      }

      if (mounted) setState(() { _loading = false; });
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
        const SizedBox(height: 24),

        // ── Recent Penjualan ──
        if (_recentSales.isNotEmpty) ...[
          Row(children: [
            Icon(Icons.sell, size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text('Penjualan Terakhir',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: cs.onSurface)),
          ]),
          const SizedBox(height: 8),
          ..._recentSales.map((s) => _miniCard(
            cs,
            icon: Icons.sell,
            iconColor: Colors.green,
            title: s['kode_penjualan'] ?? '-',
            subtitle: '${s['jumlah_item'] ?? 0} item',
            trailing: formatCurrency(toInt(s['total_harga'])),
            trailingColor: Colors.green,
          )),
          const SizedBox(height: 20),
        ],

        // ── Recent Pembelian ──
        if (_recentOrders.isNotEmpty) ...[
          Row(children: [
            Icon(Icons.shopping_cart, size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Text('Pembelian Terakhir',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: cs.onSurface)),
          ]),
          const SizedBox(height: 8),
          ..._recentOrders.map((o) {
            final st = (o['status'] ?? 'pending').toString().toLowerCase();
            Color stColor;
            String stText;
            switch (st) {
              case 'approved_admin': stColor = Colors.cyan; stText = 'Diverifikasi'; break;
              case 'dipaket': stColor = Colors.orange; stText = 'Dikemas'; break;
              case 'dikirim': stColor = cs.primary; stText = 'Dikirim'; break;
              case 'selesai': case 'diterima': stColor = Colors.green; stText = 'Selesai'; break;
              case 'rejected': stColor = Colors.red; stText = 'Ditolak'; break;
              default: stColor = Colors.amber; stText = 'Pending';
            }
            return _miniCard(
              cs,
              icon: Icons.shopping_cart,
              iconColor: Colors.orange,
              title: o['kode_order'] ?? '-',
              subtitle: '${(o['items'] as List? ?? []).length} item',
              trailing: stText,
              trailingColor: stColor,
              amount: formatCurrency(toInt(o['total_harga'])),
            );
          }),
        ],
      ]),
    );
  }

  Widget _miniCard(
    ColorScheme cs, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String trailing,
    required Color trailingColor,
    String? amount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13, color: cs.onSurface)),
            Text(subtitle,
                style: TextStyle(fontSize: 11, color: cs.outline)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: trailingColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(trailing,
                style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.bold, color: trailingColor)),
          ),
          if (amount != null) ...[
            const SizedBox(height: 2),
            Text(amount,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: cs.outline)),
          ],
        ]),
      ]),
    );
  }
}
