import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
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
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getAdminDashboard();
      if (res.statusCode == 200) {
        setState(() => _data = jsonDecode(res.body));
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (int i = 0; i < 3; i++) ...[
            ShimmerBox(
              width: double.infinity,
              height: 20,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (int j = 0; j < 3; j++) ...[
                  Expanded(
                    child: ShimmerBox(
                      width: double.infinity,
                      height: 80,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    ),
                  ),
                  if (j < 2) const SizedBox(width: 12),
                ],
              ],
            ),
            const SizedBox(height: 24),
          ],
        ],
      );
    }
    if (_data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            TextButton(onPressed: _fetch, child: const Text('Gagal memuat. Coba lagi')),
          ],
        ),
      );
    }

    final orders = _data!['orders'] ?? {};
    final users = _data!['users'] ?? {};
    final products = _data!['products'] ?? {};
    final shipments = _data!['shipments'] ?? {};

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Greeting ──
          Text(
            'Admin Panel ⚡',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ringkasan sistem hari ini',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // ── Pesanan ──
          SectionHeading(icon: Icons.receipt_long, title: 'Pesanan'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: OctaviaStatCard(icon: Icons.access_time, label: 'Pending', value: '${orders['pending'] ?? 0}', color: const Color(0xFFF59E0B))),
              const SizedBox(width: 12),
              Expanded(child: OctaviaStatCard(icon: Icons.check_circle_outline, label: 'Disetujui', value: '${orders['approved'] ?? 0}', color: OctaviaColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OctaviaStatCard(icon: Icons.inventory_2, label: 'Dikemas', value: '${orders['dipaket'] ?? 0}', color: OctaviaColors.accentPink)),
              const SizedBox(width: 12),
              Expanded(child: OctaviaStatCard(icon: Icons.local_shipping, label: 'Dikirim', value: '${orders['dikirim'] ?? 0}', color: OctaviaColors.accentGreen)),
            ],
          ),
          const SizedBox(height: 12),
          OctaviaStatCard(icon: Icons.verified, label: 'Diterima', value: '${orders['diterima'] ?? 0}', color: OctaviaColors.badgePro),
          const SizedBox(height: 24),

          // ── Pengiriman ──
          SectionHeading(icon: Icons.local_shipping, title: 'Pengiriman'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: OctaviaStatCard(icon: Icons.send, label: 'Dikirim', value: '${shipments['dikirim'] ?? 0}', color: OctaviaColors.primary)),
              const SizedBox(width: 12),
              Expanded(child: OctaviaStatCard(icon: Icons.check_circle, label: 'Diterima', value: '${shipments['diterima'] ?? 0}', color: OctaviaColors.accentGreen)),
              const SizedBox(width: 12),
              Expanded(child: OctaviaStatCard(icon: Icons.cancel_outlined, label: 'Ditolak', value: '${shipments['ditolak'] ?? 0}', color: const Color(0xFFEF4444))),
            ],
          ),
          const SizedBox(height: 24),

          // ── Pengguna ──
          SectionHeading(icon: Icons.people, title: 'Pengguna'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: OctaviaStatCard(icon: Icons.admin_panel_settings, label: 'Admin', value: '${users['admin'] ?? 0}', color: const Color(0xFFEF4444))),
              const SizedBox(width: 12),
              Expanded(child: OctaviaStatCard(icon: Icons.store, label: 'Cabang', value: '${users['cabang'] ?? 0}', color: OctaviaColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: OctaviaStatCard(icon: Icons.badge, label: 'Sales', value: '${users['sales'] ?? 0}', color: OctaviaColors.accentGreen)),
              const SizedBox(width: 12),
              Expanded(child: OctaviaStatCard(icon: Icons.warehouse, label: 'Gudang', value: '${users['gudang'] ?? 0}', color: const Color(0xFFF59E0B))),
            ],
          ),
          const SizedBox(height: 24),

          // ── Produk ──
          SectionHeading(icon: Icons.inventory_2, title: 'Produk'),
          const SizedBox(height: 10),
          OctaviaStatCard(icon: Icons.category, label: 'Total Produk', value: '${products['total'] ?? 0}', color: OctaviaColors.badgePro),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
