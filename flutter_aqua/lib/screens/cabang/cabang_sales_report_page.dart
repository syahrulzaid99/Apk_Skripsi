import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../widgets/smooth_list_item.dart';

class CabangSalesReportPage extends StatelessWidget {
  const CabangSalesReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Pembelian'),
        centerTitle: true,
      ),
      body: const _PembelianTab(),
    );
  }
}

// ═══════════════════════ PEMBELIAN TAB ═══════════════════════

class _PembelianTab extends StatefulWidget {
  const _PembelianTab();

  @override
  State<_PembelianTab> createState() => _PembelianTabState();
}

class _PembelianTabState extends State<_PembelianTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getOrders();
      if (res.statusCode == 200) {
        _orders = (jsonDecode(res.body)['orders'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        _snack('Gagal memuat pesanan');
      }
    } catch (_) {
      _snack('Gagal terhubung ke server');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerBox(
              width: double.infinity,
              height: 80,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    // Summary
    int totalBeli = 0, totalItem = 0;
    for (final o in _orders) {
      totalBeli += toInt(o['total_harga']);
      final items = o['items'] as List? ?? [];
      for (final it in items) {
        totalItem += toInt(it['qty']);
      }
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.2)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.orange.shade700, size: 24),
                      const SizedBox(height: 8),
                      Text('Total Pembelian',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.outline,
                              fontWeight: FontWeight.w500)),
                      Text(formatCurrency(totalBeli),
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700)),
                    ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withOpacity(0.15)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.inventory_2, color: cs.primary, size: 24),
                      const SizedBox(height: 8),
                      Text('Item Dibeli',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.outline,
                              fontWeight: FontWeight.w500)),
                      Text('$totalItem',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cs.primary)),
                    ]),
              ),
            ),
          ]),
          const SizedBox(height: 20),
          _sectionTitle(cs, Icons.list_alt, 'Riwayat Pembelian'),
          const SizedBox(height: 8),
          if (_orders.isEmpty)
            _emptyState(cs, Icons.shopping_cart_outlined,
                'Belum ada pesanan pembelian'),
          ..._orders.map((o) => _orderCard(o, cs)),
        ],
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> o, ColorScheme cs) {
    final status = (o['status'] ?? 'pending').toString().toLowerCase();
    final dateStr = _formatDate(o['createdAt']);
    final itemCount = o['items'] is List ? (o['items'] as List).length : 0;

    Color statusColor;
    String statusText;
    switch (status) {
      case 'approved_admin':
        statusColor = Colors.cyan;
        statusText = 'DIVERIFIKASI';
        break;
      case 'dipaket':
        statusColor = Colors.orange;
        statusText = 'DIKEMAS';
        break;
      case 'dikirim':
        statusColor = cs.primary;
        statusText = 'DIKIRIM';
        break;
      case 'selesai':
      case 'diterima':
        statusColor = Colors.green;
        statusText = 'SELESAI';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'DITOLAK';
        break;
      default:
        statusColor = Colors.amber;
        statusText = 'PENDING';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(Icons.shopping_cart, color: Colors.orange.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(o['kode_order'] ?? '-',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: cs.onSurface)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(statusText,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor)),
                ),
              ]),
              const SizedBox(height: 4),
              Text('$itemCount item${dateStr.isNotEmpty ? ' · $dateStr' : ''}',
                  style: TextStyle(fontSize: 12, color: cs.outline)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(formatCurrency(toInt(o['total_harga'])),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.orange.shade700)),
      ]),
    );
  }
}

// ═══════════════════════ SHARED HELPERS ═══════════════════════

Widget _sectionTitle(ColorScheme cs, IconData icon, String text) {
  return Row(children: [
    Icon(icon, size: 18, color: cs.primary),
    const SizedBox(width: 6),
    Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
  ]);
}

Widget _statChip(IconData icon, String label, String value, ColorScheme cs) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
    ),
    child: Row(children: [
      Icon(icon, size: 20, color: cs.primary),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 11, color: cs.outline, fontWeight: FontWeight.w500)),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.onSurface)),
      ]),
    ]),
  );
}

Widget _emptyState(ColorScheme cs, IconData icon, String text) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(children: [
        Icon(icon, size: 64, color: cs.outline.withOpacity(0.4)),
        const SizedBox(height: 12),
        Text(text, style: TextStyle(color: cs.outline, fontSize: 15)),
      ]),
    ),
  );
}

String _formatDate(dynamic createdAt) {
  if (createdAt == null) return '';
  try {
    DateTime dt;
    if (createdAt is Map && createdAt['_seconds'] != null) {
      dt = DateTime.fromMillisecondsSinceEpoch(
          (createdAt['_seconds'] as int) * 1000);
    } else {
      dt = DateTime.parse(createdAt.toString());
    }
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  } catch (_) {
    return '';
  }
}

String _compact(int v) {
  if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}M';
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
  return v.toString();
}
