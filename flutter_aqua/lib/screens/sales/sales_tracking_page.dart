import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../widgets/smooth_list_item.dart';

/// Menu tracking pengiriman untuk sales — progres pesanan cabang dari
/// konfirmasi sales, verifikasi admin, pengemasan, kirim, hingga diterima.
class SalesTrackingPage extends StatefulWidget {
  const SalesTrackingPage({super.key, this.initialOrders});

  /// Data pesanan awal (untuk widget test / preview). Saat diisi, halaman
  /// tidak melakukan fetch dari server.
  final List<Map<String, dynamic>>? initialOrders;

  @override
  State<SalesTrackingPage> createState() => _SalesTrackingPageState();
}

class _SalesTrackingPageState extends State<SalesTrackingPage> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String _filter = 'semua'; // semua | proses | selesai | ditolak

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  void initState() {
    super.initState();
    final inj = widget.initialOrders;
    if (inj != null) {
      _orders = inj;
      _loading = false;
    } else {
      _fetch();
    }
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getSalesTracking();
      if (res.statusCode == 200) {
        _orders = (jsonDecode(res.body)['orders'] as List? ?? [])
            .cast<Map<String, dynamic>>();
      } else {
        _snack('Gagal memuat tracking (${res.statusCode})');
      }
    } catch (_) {
      _snack('Gagal memuat tracking');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      if (v is Map && v['_seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(
            ((v['_seconds'] as num).toInt()) * 1000);
      }
      return DateTime.parse(v.toString());
    } catch (_) {
      return null;
    }
  }

  String _fmt(dynamic v, {bool withTime = true}) {
    final d = _parseDate(v);
    if (d == null) return '—';
    final t = '${d.day.toString().padLeft(2, '0')} ${_months[d.month - 1]} ${d.year}';
    if (!withTime) return t;
    final hm = '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$t $hm';
  }

  /// -1 = ditolak, 0 = dibuat, 1..5 = tahap pengiriman
  int _rankOf(String s) {
    switch (s) {
      case 'approved_sales':
        return 1;
      case 'approved_admin':
        return 2;
      case 'dipaket':
        return 3;
      case 'dikirim':
        return 4;
      case 'diterima':
      case 'selesai':
        return 5;
      case 'rejected':
      case 'ditolak':
        return -1;
      default:
        return 0;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending':
        return 'Pesanan dibuat';
      case 'approved_sales':
        return 'Dikonfirmasi sales';
      case 'approved_admin':
        return 'Diverifikasi admin';
      case 'dipaket':
        return 'Dikemas gudang';
      case 'dikirim':
        return 'Dikirim';
      case 'diterima':
        return 'Diterima cabang';
      case 'selesai':
        return 'Selesai';
      case 'rejected':
        return 'Ditolak';
      case 'ditolak':
        return 'Ditolak admin';
      default:
        return s;
    }
  }

  Color _dotColor(String s) {
    switch (s) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'dikirim':
        return OctaviaColors.primary;
      case 'diterima':
      case 'selesai':
        return OctaviaColors.accentGreen;
      case 'rejected':
      case 'ditolak':
        return const Color(0xFFEF4444);
      case 'approved_admin':
        return OctaviaColors.badgePro;
      default:
        return OctaviaColors.primary;
    }
  }

  String _displayName(Map<String, dynamic> o) {
    final nama = (o['cabang_nama'] ?? '').toString();
    if (nama.isNotEmpty) return nama;
    return (o['cabang_username'] ?? '-').toString();
  }

  List<Map<String, dynamic>> _buildTimeline(Map<String, dynamic> o) {
    final tl = <Map<String, dynamic>>[];
    final hist = o['history'];
    if (hist is List && hist.isNotEmpty) {
      for (final h in hist) {
        final hs = (h['status'] ?? '').toString().toLowerCase();
        final sub = StringBuffer('oleh ${h['by_username'] ?? '-'}');
        final note = (h['note'] ?? '').toString();
        if (note.isNotEmpty) sub.write(' · $note');
        tl.add({
          'label': _statusLabel(hs),
          'sub': sub.toString(),
          'time': _fmt(h['at'], withTime: true),
          'color': _dotColor(hs),
        });
      }
      return tl;
    }

    // Fallback untuk order lama tanpa history
    void addIf(String label, dynamic v, String key) {
      if (v == null) return;
      final d = _parseDate(v);
      if (d != null) {
        tl.add({
          'label': label,
          'sub': '',
          'time': _fmt(d, withTime: true),
          'color': _dotColor(key),
        });
      }
    }

    addIf('Pesanan dibuat', o['createdAt'], 'pending');
    addIf('Dikonfirmasi sales', o['approved_sales_at'], 'approved_sales');
    addIf('Diverifikasi admin', o['approved_admin_at'], 'approved_admin');
    addIf('Dikemas gudang', o['packed_at'], 'dipaket');

    final resi = (o['kode_pengiriman'] ?? '').toString();
    if (resi.isNotEmpty) {
      tl.add({
        'label': 'Dikirim',
        'sub': 'Resi $resi',
        'time': _fmt(o['dikirim_at'] ?? o['createdAt'], withTime: true),
        'color': _dotColor('dikirim'),
      });
    }

    final st = (o['status'] ?? '').toString().toLowerCase();
    if (st == 'diterima' || st == 'selesai') {
      final oleh = (o['diterima_oleh'] ?? '').toString();
      tl.add({
        'label': 'Diterima cabang',
        'sub': oleh.isNotEmpty ? 'oleh $oleh' : '',
        'time': _fmt(o['diterima_at'] ?? o['createdAt'], withTime: true),
        'color': _dotColor('diterima'),
      });
    }
    if (st == 'rejected' || st == 'ditolak') {
      tl.add({
        'label': _statusLabel(st),
        'sub': (o['rejection_reason'] ?? '').toString(),
        'time': _fmt(o['rejected_at'], withTime: true),
        'color': _dotColor(st),
      });
    }
    return tl;
  }

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => const ShimmerCard(),
      );
    }

    var nTotal = _orders.length, nProses = 0, nSelesai = 0, nDitolak = 0;
    for (final o in _orders) {
      final r = _rankOf((o['status'] ?? '').toString().toLowerCase());
      if (r == -1) {
        nDitolak++;
      } else if (r >= 5) {
        nSelesai++;
      } else {
        nProses++;
      }
    }

    final filtered = _orders.where((o) {
      final r = _rankOf((o['status'] ?? '').toString().toLowerCase());
      final bucket = r == -1
          ? 'ditolak'
          : (r >= 5 ? 'selesai' : 'proses');
      return _filter == 'semua' || bucket == _filter;
    }).toList();

    return Column(children: [
      // KPI
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            // Tinggi sel tetap (bukan rasio) agar kartu stat muat; kartu
            // sendiri sudah anti-overflow via FittedBox di OctaviaStatCard.
            mainAxisExtent: 140,
          ),
          children: [
            OctaviaStatCard(
              icon: Icons.inventory_2,
              label: 'Total pesanan',
              value: '$nTotal',
              color: OctaviaColors.primary,
            ),
            OctaviaStatCard(
              icon: Icons.route,
              label: 'Dalam proses',
              value: '$nProses',
              color: const Color(0xFFF59E0B),
            ),
            OctaviaStatCard(
              icon: Icons.check_circle,
              label: 'Selesai diterima',
              value: '$nSelesai',
              color: OctaviaColors.accentGreen,
            ),
            OctaviaStatCard(
              icon: Icons.cancel,
              label: 'Ditolak',
              value: '$nDitolak',
              color: const Color(0xFFEF4444),
            ),
          ],
        ),
      ),

      // Filter
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          for (final f in [
            ['semua', 'Semua'],
            ['proses', 'Dalam proses'],
            ['selesai', 'Selesai'],
            ['ditolak', 'Ditolak'],
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f[1]),
                selected: _filter == f[0],
                onSelected: (_) => setState(() => _filter = f[0]),
              ),
            ),
        ]),
      ),

      // Daftar
      Expanded(
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: filtered.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Tidak ada pesanan')),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final o = filtered[i];
                    final st = (o['status'] ?? '').toString().toLowerCase();
                    final rank = _rankOf(st);
                    final resi = (o['kode_pengiriman'] ?? '').toString();
                    final jml = o['jumlah_item'] ?? 0;

                    return SmoothListItem(
                      index: i,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showDetail(o),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(o['kode_order'] ?? '-',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: cs.primary)),
                                  ),
                                  StatusChip(status: st),
                                ]),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Flexible(
                                    child: Text(
                                      'Cabang: ${_displayName(o)}',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          color: cs.outline, fontSize: 13),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '$jml item | ${formatCurrency(o['total_harga'] ?? 0)}',
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          color: cs.outline, fontSize: 13),
                                    ),
                                  ),
                                ]),
                                if (resi.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Icon(Icons.receipt_long,
                                        size: 14, color: cs.outline),
                                    const SizedBox(width: 4),
                                    Text(
                                      resi,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: OctaviaColors.primary,
                                      ),
                                    ),
                                  ]),
                                ],
                                const SizedBox(height: 10),
                                if (rank == -1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.block,
                                            size: 14,
                                            color: Color(0xFFEF4444)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Ditolak',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  _ProgressStepper(rank: rank),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    ]);
  }

  // ── Detail bottom sheet ────────────────────────────────────────────

  void _showDetail(Map<String, dynamic> o) {
    final cs = Theme.of(context).colorScheme;
    final st = (o['status'] ?? '').toString().toLowerCase();
    final resi = (o['kode_pengiriman'] ?? '').toString();
    final items = o['items'] is List ? (o['items'] as List) : <dynamic>[];
    final timeline = _buildTimeline(o);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(children: [
              Expanded(
                child: Text(o['kode_order'] ?? '-',
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface)),
              ),
              StatusChip(status: st),
            ]),
            const SizedBox(height: 12),
            InfoRow(
                icon: Icons.store,
                label: 'Cabang',
                value: _displayName(o)),
            InfoRow(
                icon: Icons.calendar_today,
                label: 'Tanggal',
                value: _fmt(o['createdAt'], withTime: false)),
            InfoRow(
                icon: Icons.payments,
                label: 'Total',
                value: formatCurrency(o['total_harga'] ?? 0)),
            if (resi.isNotEmpty)
              InfoRow(
                  icon: Icons.receipt_long, label: 'Resi', value: resi),
            if (st == 'rejected' || st == 'ditolak')
              InfoRow(
                  icon: Icons.report,
                  label: 'Alasan',
                  value: (o['rejection_reason'] ?? '—').toString()),
            const SizedBox(height: 16),
            const SectionHeading(icon: Icons.inventory_2, title: 'Barang'),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text('Tidak ada item.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))
            else
              Card(
                margin: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Row(children: [
                          Expanded(
                            child: Text(
                              (items[i]['nama_produk'] ?? '-').toString(),
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface),
                            ),
                          ),
                          Text(
                            '${items[i]['qty'] ?? 0} pcs',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant),
                          ),
                        ]),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const SectionHeading(icon: Icons.route, title: 'Progres status'),
            const SizedBox(height: 12),
            if (timeline.isEmpty)
              Text('Belum ada riwayat status.',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13))
            else
              for (var i = 0; i < timeline.length; i++)
                _TimelineRow(
                  event: timeline[i],
                  isLast: i == timeline.length - 1,
                ),
          ],
        ),
      ),
    );
  }
}

/// Stepper horizontal 5 tahap: Sales → Admin → Kemas → Kirim → Terima
class _ProgressStepper extends StatelessWidget {
  final int rank; // 0..5
  const _ProgressStepper({required this.rank});

  static const _labels = ['Sales', 'Admin', 'Kemas', 'Kirim', 'Terima'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const doneColor = OctaviaColors.accentGreen;
    const currentColor = OctaviaColors.primary;
    final idleColor = cs.outlineVariant;

    // Tinggi mengikuti konten (tanpa SizedBox kaku) — tidak pernah overflow,
    // termasuk saat skala font sistem diperbesar.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < 5; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: i == 0
                          ? const SizedBox.shrink()
                          : Container(
                              height: 2,
                              color: i < rank && rank > 0
                                  ? doneColor
                                  : idleColor,
                            ),
                    ),
                    Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i + 1 <= rank
                            ? doneColor
                            : (i + 1 == rank + 1 && rank > 0
                                ? currentColor
                                : cs.surface),
                        border: Border.all(
                          color: i + 1 <= rank
                              ? doneColor
                              : (i + 1 == rank + 1 && rank > 0
                                  ? currentColor
                                  : idleColor),
                          width: 2,
                        ),
                      ),
                    ),
                    Expanded(
                      child: i == 4
                          ? const SizedBox.shrink()
                          : Container(
                              height: 2,
                              color: (i + 1) < rank && rank > 0
                                  ? doneColor
                                  : idleColor,
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  _labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight:
                        (i + 1 <= rank || (i + 1 == rank + 1 && rank > 0))
                            ? FontWeight.w600
                            : FontWeight.w400,
                    color: (i + 1 <= rank ||
                            (i + 1 == rank + 1 && rank > 0))
                        ? cs.onSurface
                        : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Satu baris timeline vertikal (titik + konten)
class _TimelineRow extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isLast;

  const _TimelineRow({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = event['color'] as Color? ?? OctaviaColors.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          if (!isLast)
            Container(width: 2, height: 30, color: cs.outlineVariant),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (event['label'] ?? '-').toString(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                if ((event['sub'] ?? '').toString().isNotEmpty)
                  Text(
                    (event['sub'] ?? '').toString(),
                    style: GoogleFonts.inter(
                        fontSize: 11, color: cs.onSurfaceVariant),
                  ),
                Text(
                  (event['time'] ?? '—').toString(),
                  style: GoogleFonts.inter(
                      fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
