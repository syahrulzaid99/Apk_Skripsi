import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
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
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final dashRes = await ApiClient.getDashboard();
      if (dashRes.statusCode == 200) {
        final data = jsonDecode(dashRes.body);
        _stats = data['stats'] as Map<String, dynamic>?;
      }

      final ordersRes = await ApiClient.getGudangOrders();
      if (ordersRes.statusCode == 200) {
        final all = (jsonDecode(ordersRes.body)['orders'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        _recentOrders = all.take(5).toList();
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            Expanded(
              child: ShimmerBox(
                width: double.infinity,
                height: 100,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ShimmerBox(
                width: double.infinity,
                height: 100,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          ShimmerBox(
            width: double.infinity,
            height: 100,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          const SizedBox(height: 24),
          for (int i = 0; i < 3; i++) ...[
            ShimmerBox(
              width: double.infinity,
              height: 60,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
    }
    final cs = Theme.of(context).colorScheme;
    final readyToPack = _stats?['readyToPack'] ?? 0;
    final packed = _stats?['packed'] ?? 0;
    final sent = _stats?['sent'] ?? 0;

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Greeting ──
          Text(
            'Gudang 📦',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola pengemasan dan pengiriman',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // ── Stat cards ──
          Row(children: [
            Expanded(
              child: OctaviaStatCard(
                icon: Icons.inventory,
                label: 'Siap Dikemas',
                value: '$readyToPack',
                color: OctaviaColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OctaviaStatCard(
                icon: Icons.inventory_2,
                label: 'Dikemas',
                value: '$packed',
                color: const Color(0xFFF59E0B),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          OctaviaStatCard(
            icon: Icons.local_shipping,
            label: 'Dalam Pengiriman',
            value: '$sent',
            color: OctaviaColors.accentGreen,
          ),
          const SizedBox(height: 24),

          // ── Recent orders ──
          if (_recentOrders.isNotEmpty) ...[
            SectionHeading(icon: Icons.receipt_long, title: 'Pesanan Terbaru'),
            const SizedBox(height: 10),
            for (final o in _recentOrders)
              OctaviaMiniCard(
                icon: _statusIcon(o['status']),
                iconColor: _statusColor(o['status']),
                title: o['kode_order'] ?? '-',
                subtitle:
                    '${o['cabang_nama'] ?? o['cabang_username'] ?? '-'} • ${o['jumlah_item'] ?? 0} item',
                trailing: formatCurrency(o['total_harga'] ?? 0),
                trailingColor: OctaviaColors.primary,
              ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved_admin':
        return OctaviaColors.primary;
      case 'dipaket':
        return const Color(0xFFF59E0B);
      case 'dikirim':
        return OctaviaColors.accentGreen;
      default:
        return OctaviaColors.textMuted;
    }
  }

  IconData _statusIcon(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'approved_admin':
        return Icons.check_circle;
      case 'dipaket':
        return Icons.inventory_2;
      case 'dikirim':
        return Icons.local_shipping;
      default:
        return Icons.help_outline;
    }
  }
}
