import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
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
  List<Map<String, dynamic>> _recentOrders = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final results = await Future.wait([
        ApiClient.getDashboard(),
        ApiClient.getOrders(),
      ]);

      final dashRes = results[0];
      final ordersRes = results[1];

      if (dashRes.statusCode == 200) {
        final data = jsonDecode(dashRes.body);
        _stokMasuk = data['stok_masuk'] ?? 0;
        _stokTersedia = data['stok_tersedia'] ?? [];
      }

      if (ordersRes.statusCode == 200) {
        _recentOrders = (jsonDecode(ordersRes.body)['orders'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .take(5)
            .toList();
      }

      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Terjadi kesalahan jaringan.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ShimmerBox(
            width: double.infinity,
            height: 100,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: ShimmerBox(
                width: double.infinity,
                height: 90,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ShimmerBox(
                width: double.infinity,
                height: 90,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
            ),
          ]),
        ],
      );
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(_error,
                style: GoogleFonts.inter(color: const Color(0xFFEF4444))),
            const SizedBox(height: 16),
            FilledButton(onPressed: _fetch, child: const Text('Coba Lagi')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Greeting ──
          Text(
            'Halo! 👋',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pantau stok dan pesananmu hari ini',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // ── Main stat card ──
          OctaviaCard(
            color: OctaviaColors.primary,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2, size: 24, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Pengiriman',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      Text(
                        '$_stokMasuk',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Stok Toko card ──
          OctaviaCard(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StoreStockPage(stokTersedia: _stokTersedia),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: OctaviaColors.accentGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront, size: 22, color: OctaviaColors.accentGreen),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stok Toko',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        'Lihat ketersediaan stok di toko saat ini',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Recent Pembelian ──
          if (_recentOrders.isNotEmpty) ...[
            SectionHeading(
              icon: Icons.shopping_cart,
              title: 'Pembelian Terakhir',
            ),
            const SizedBox(height: 10),
            ..._recentOrders.map((o) {
              final st = (o['status'] ?? 'pending').toString().toLowerCase();
              Color stColor;
              String stText;
              switch (st) {
                case 'approved_admin':
                  stColor = OctaviaColors.badgePro;
                  stText = 'Diverifikasi';
                  break;
                case 'dipaket':
                  stColor = const Color(0xFFF59E0B);
                  stText = 'Dikemas';
                  break;
                case 'dikirim':
                  stColor = OctaviaColors.primary;
                  stText = 'Dikirim';
                  break;
                case 'selesai':
                case 'diterima':
                  stColor = OctaviaColors.accentGreen;
                  stText = 'Selesai';
                  break;
                case 'rejected':
                  stColor = const Color(0xFFEF4444);
                  stText = 'Ditolak';
                  break;
                default:
                  stColor = const Color(0xFFF59E0B);
                  stText = 'Pending';
              }
              return OctaviaMiniCard(
                icon: Icons.shopping_cart,
                iconColor: const Color(0xFFF59E0B),
                title: o['kode_order'] ?? '-',
                subtitle: '${(o['items'] as List? ?? []).length} item',
                trailing: stText,
                trailingColor: stColor,
                amount: formatCurrency(toInt(o['total_harga'])),
              );
            }),
          ],
        ],
      ),
    );
  }
}
