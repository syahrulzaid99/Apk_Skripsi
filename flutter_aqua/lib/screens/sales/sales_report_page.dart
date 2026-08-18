import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../widgets/smooth_list_item.dart';

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key, this.initialReport});

  /// Data laporan awal (untuk widget test / preview). Saat diisi, halaman
  /// tidak melakukan fetch dari server.
  final Map<String, dynamic>? initialReport;

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _monthly = [];
  List<Map<String, dynamic>> _branches = [];
  List<Map<String, dynamic>> _recentOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final inj = widget.initialReport;
    if (inj != null) {
      _summary = inj['summary'] as Map<String, dynamic>? ?? {};
      _monthly = (inj['monthly'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _branches = (inj['branches'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _recentOrders = (inj['recentOrders'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _loading = false;
    } else {
      _fetch();
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getSalesReport();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _summary = data['summary'] as Map<String, dynamic>? ?? {};
        _monthly = (data['monthly'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _branches = (data['branches'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _recentOrders = (data['recentOrders'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else {
        _snack('Gagal memuat laporan');
      }
    } catch (_) {
      _snack('Gagal terhubung ke server');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ShimmerBox(
              width: double.infinity,
              height: 100,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Summary ──
          _buildSummarySection(cs),
          const SizedBox(height: 20),

          // ── Monthly Chart ──
          if (_monthly.isNotEmpty) ...[
            _sectionTitle(Icons.bar_chart, 'Pendapatan per Bulan'),
            const SizedBox(height: 8),
            _buildMonthlyChart(cs),
            const SizedBox(height: 20),
          ],

          // ── Per-Cabang Breakdown ──
          if (_branches.isNotEmpty) ...[
            _sectionTitle(Icons.store, 'Per Cabang'),
            const SizedBox(height: 8),
            ..._branches.asMap().entries.map((entry) {
              final idx = entry.key;
              final b = entry.value;
              return _buildBranchCard(b, idx, cs);
            }),
            const SizedBox(height: 20),
          ],

          // ── Recent Orders ──
          if (_recentOrders.isNotEmpty) ...[
            _sectionTitle(Icons.receipt_long, 'Pesanan Terakhir'),
            const SizedBox(height: 8),
            ..._recentOrders.map((o) => _buildOrderCard(o, cs)),
          ],

          // ── Empty State ──
          if (_summary == null || (_summary!['totalOrders'] ?? 0) == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Icon(Icons.assessment_outlined,
                        size: 64, color: cs.outline.withOpacity(0.4)),
                    const SizedBox(height: 12),
                    Text('Belum ada data pesanan',
                        style: TextStyle(color: cs.outline, fontSize: 15)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(ColorScheme cs) {
    final totalPendapatan = toInt(_summary?['totalPendapatan']);
    final totalOrders = _summary?['totalOrders'] ?? 0;
    final totalItem = _summary?['totalItem'] ?? 0;

    return Column(
      children: [
        // Revenue card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Pendapatan',
                  style: TextStyle(
                      color: cs.onPrimary.withOpacity(0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(formatCurrency(totalPendapatan),
                  style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _statChip(Icons.shopping_bag_outlined, 'Pesanan',
                    '$totalOrders', cs)),
            const SizedBox(width: 10),
            Expanded(
                child: _statChip(Icons.inventory_2_outlined, 'Item Terjual',
                    '$totalItem', cs)),
          ],
        ),
      ],
    );
  }

  Widget _statChip(
      IconData icon, String label, String value, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: cs.primary),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11,
                        color: cs.outline,
                        fontWeight: FontWeight.w500)),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart(ColorScheme cs) {
    final maxVal = _monthly
        .map((m) => toInt(m['total']))
        .fold<int>(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _monthly.map((m) {
                final total = toInt(m['total']);
                final ratio = maxVal > 0 ? (total / maxVal) : 0.0;
                var hFactor = ratio;
                if (hFactor <= 0) {
                  hFactor = 0.0;
                } else if (hFactor < 0.05) {
                  hFactor = 0.05;
                } else if (hFactor > 1.0) {
                  hFactor = 1.0;
                }
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      children: [
                        if (total > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _compactCurrency(total),
                              maxLines: 1,
                              style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: cs.outline),
                            ),
                          ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: hFactor,
                              widthFactor: 1,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cs.primary
                                      .withValues(alpha: 0.8),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _monthly.map((m) {
              return Expanded(
                child: Text(
                  (m['label'] ?? '').toString().split(' ').first,
                  style: TextStyle(fontSize: 9, color: cs.outline),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Count row
          Row(
            children: _monthly.map((m) {
              return Expanded(
                child: Text(
                  '${m['count'] ?? 0}',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: cs.primary),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> o, ColorScheme cs) {
    final status = (o['status'] ?? 'pending').toString().toLowerCase();
    final createdAt = o['createdAt'];
    String dateStr = '';
    if (createdAt != null) {
      try {
        DateTime dt;
        if (createdAt is Map && createdAt['_seconds'] != null) {
          dt = DateTime.fromMillisecondsSinceEpoch(
              (createdAt['_seconds'] as int) * 1000);
        } else {
          dt = DateTime.parse(createdAt.toString());
        }
        dateStr =
            '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {}
    }

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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.shopping_cart, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(o['kode_order'] ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: cs.onSurface)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
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
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    '${o['cabang_username'] ?? '-'}${dateStr.isNotEmpty ? ' · $dateStr' : ''}',
                    style: TextStyle(fontSize: 12, color: cs.outline)),
                Text('${o['jumlah_item'] ?? 0} item',
                    style: TextStyle(fontSize: 12, color: cs.outline)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(formatCurrency(toInt(o['total_harga'])),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: cs.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard(Map<String, dynamic> b, int idx, ColorScheme cs) {
    final rankColors = [
      Colors.blue,
      Colors.indigo,
      Colors.cyan,
      Colors.green,
      Colors.amber,
      Colors.pink,
    ];
    final color = rankColors[idx % rankColors.length];
    final monthly = (b['monthly'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final maxVal = monthly
        .map((m) => toInt(m['total']))
        .fold<int>(1, (a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('${idx + 1}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          b['nama_cabang']?.toString().isNotEmpty == true
                              ? b['nama_cabang']
                              : b['username'] ?? '-',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: cs.onSurface)),
                      if (b['kota']?.toString().isNotEmpty == true ||
                          b['provinsi']?.toString().isNotEmpty == true)
                        Text(
                            '${b['kota'] ?? ''}${b['provinsi'] != null ? ', ${b['provinsi']}' : ''}',
                            style:
                                TextStyle(fontSize: 12, color: cs.outline)),
                    ],
                  ),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatCurrency(toInt(b['totalPendapatan'])),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.green.shade700)),
                      Text(
                          '${b['totalOrders'] ?? 0} pesanan · ${b['totalItem'] ?? 0} item',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: cs.outline)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Mini chart — tinggi bar proporsional terhadap area yang tersisa
          // (FractionallySizedBox di dalam Expanded) supaya tidak pernah
          // overflow, termasuk saat skala font sistem diperbesar.
          if (monthly.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SizedBox(
                height: 52,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: monthly.map((m) {
                    final total = toInt(m['total']);
                    final ratio = maxVal > 0 ? (total / maxVal) : 0.0;
                    var hFactor = ratio;
                    if (hFactor <= 0) {
                      hFactor = 0.0;
                    } else if (hFactor < 0.07) {
                      hFactor = 0.07;
                    } else if (hFactor > 1.0) {
                      hFactor = 1.0;
                    }
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: hFactor,
                                  widthFactor: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.7),
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                                (m['label'] ?? '')
                                    .toString()
                                    .split(' ')
                                    .first,
                                maxLines: 1,
                                style: TextStyle(
                                    fontSize: 7, color: cs.outline),
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _compactCurrency(int v) {
    if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}M';
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}jt';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}rb';
    return v.toString();
  }
}
