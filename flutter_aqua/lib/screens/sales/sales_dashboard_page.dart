import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../widgets/smooth_list_item.dart';

class SalesDashboardPage extends StatefulWidget {
  const SalesDashboardPage({super.key});

  @override
  State<SalesDashboardPage> createState() => _SalesDashboardPageState();
}

class _SalesDashboardPageState extends State<SalesDashboardPage> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getDashboard();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() => _stats = data['stats'] as Map<String, dynamic>?);
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
    final cs = Theme.of(context).colorScheme;
    final pending = _stats?['pending'] ?? 0;
    final inProcess = _stats?['approved'] ?? 0;
    final completed = _stats?['rejected'] ?? 0;

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Greeting ──
          Text(
            'Sales Dashboard 📊',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pantau status pesananmu',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),

          // ── Pending card (highlight) ──
          OctaviaCard(
            color: const Color(0xFFF59E0B),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time_outlined, size: 24, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      Text(
                        '$pending',
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

          // ── Process & Completed ──
          Row(
            children: [
              Expanded(
                child: OctaviaStatCard(
                  icon: Icons.sync,
                  label: 'Dalam Proses',
                  value: '$inProcess',
                  color: OctaviaColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OctaviaStatCard(
                  icon: Icons.check_circle,
                  label: 'Selesai',
                  value: '$completed',
                  color: OctaviaColors.accentGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
