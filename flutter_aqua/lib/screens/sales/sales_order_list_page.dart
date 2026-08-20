import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../widgets/smooth_list_item.dart';

class SalesOrderListPage extends StatefulWidget {
  const SalesOrderListPage({super.key});

  @override
  State<SalesOrderListPage> createState() => _SalesOrderListPageState();
}

class _SalesOrderListPageState extends State<SalesOrderListPage> {
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _cabangs = [];
  bool _loading = true;
  String _filterStatus = 'semua';
  String? _filterCabang;
  String? _actionId;

  @override
  void initState() {
    super.initState();
    _fetch();
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
      final res = await ApiClient.getSalesOrders();
      if (res.statusCode == 200) {
        _orders = (jsonDecode(res.body)['orders'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        // Kumpulkan daftar cabang unik untuk filter
        final seen = <String>{};
        final list = <Map<String, dynamic>>[];
        for (final o in _orders) {
          final cid = o['cabang_id']?.toString();
          if (cid != null && cid.isNotEmpty && !seen.contains(cid)) {
            seen.add(cid);
            final nama = (o['cabang_nama'] ?? '').toString();
            final user = (o['cabang_username'] ?? cid).toString();
            list.add({
              'id': cid,
              'username': user,
              'cabang_nama': nama.isNotEmpty ? nama : null,
            });
          }
        }
        _cabangs = list;
      }
    } catch (_) {
      _snack('Gagal memuat');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _orders.where((o) {
      final st = (o['status'] ?? '').toString().toLowerCase();
      final matchStatus = _filterStatus == 'semua' || st == _filterStatus;
      final matchCabang =
          _filterCabang == null || (o['cabang_id']?.toString() ?? '') == _filterCabang;
      return matchStatus && matchCabang;
    }).toList();
  }

  bool _isPaid(Map<String, dynamic> o) {
    final ps = (o['payment_status'] ?? '').toString().toLowerCase();
    return ps == 'settlement' || ps == 'capture';
  }

  bool _canConfirm(Map<String, dynamic> o) {
    final st = (o['status'] ?? '').toString().toLowerCase();
    return st == 'pending' && _isPaid(o);
  }

  /// Konfirmasi pesanan cabang (status pending + sudah dibayar) ke admin.
  Future<void> _approve(Map<String, dynamic> o) async {
    final id = o['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final keterangan = await _showApproveDialog(o);
    if (keterangan == null) return;

    setState(() => _actionId = id);
    try {
      final res = await ApiClient.salesApproveOrder(id,
          keterangan: keterangan);
      if (res.statusCode == 200) {
        _snack('Pesanan ${o['kode_order'] ?? ''} dikonfirmasi ke admin');
        _fetch();
      } else {
        _snack('Gagal konfirmasi (${res.statusCode}): ${_errMessage(res.body)}');
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _actionId = null);
    }
  }

  /// Tolak pesanan cabang — alasan wajib diisi, stok pusat dikembalikan.
  Future<void> _reject(Map<String, dynamic> o) async {
    final id = o['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final alasan = await _showRejectDialog(o);
    if (alasan == null) return;

    setState(() => _actionId = id);
    try {
      final res = await ApiClient.salesRejectOrder(id, alasan: alasan);
      if (res.statusCode == 200) {
        _snack('Pesanan ${o['kode_order'] ?? ''} ditolak');
        _fetch();
      } else {
        _snack('Gagal menolak (${res.statusCode}): ${_errMessage(res.body)}');
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _actionId = null);
    }
  }

  String _errMessage(String body) {
    try {
      return (jsonDecode(body)['message'] as String?) ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Dialog konfirmasi — keterangan opsional. Mengembalikan teks catatan
  /// atau null bila dibatalkan.
  Future<String?> _showApproveDialog(Map<String, dynamic> o) {
    final ctrl = TextEditingController();
    final cs = Theme.of(context).colorScheme;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi pesanan?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pesanan ${o['kode_order'] ?? ''} sudah dibayar cabang. '
              'Dikonfirmasi dan diteruskan ke admin untuk verifikasi pengiriman.',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Catatan untuk admin (opsional)',
                isDense: true,
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Ya, konfirmasi'),
          ),
        ],
      ),
    );
  }

  /// Dialog tolak — alasan wajib diisi. Mengembalikan alasan atau null
  /// bila dibatalkan.
  Future<String?> _showRejectDialog(Map<String, dynamic> o) {
    final ctrl = TextEditingController();
    final cs = Theme.of(context).colorScheme;
    String? error;
    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Tolak pesanan?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pesanan ${o['kode_order'] ?? ''} akan ditolak. '
                'Stok pusat dikembalikan otomatis.',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: 'Alasan penolakan (wajib)',
                  isDense: true,
                  errorText: error,
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error,
              ),
              onPressed: () {
                final v = ctrl.text.trim();
                if (v.isEmpty) {
                  setSt(() => error = 'Alasan penolakan wajib diisi');
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: const Text('Ya, tolak'),
            ),
          ],
        ),
      ),
    );
  }

  String _displayName(Map<String, dynamic> o) {
    final nama = (o['cabang_nama'] ?? '').toString();
    if (nama.isNotEmpty) return nama;
    return (o['cabang_username'] ?? '-').toString();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading) return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => const ShimmerCard(),
    );

    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          for (final f in [
            'semua',
            'pending',
            'approved_sales',
            'approved_admin',
            'dipaket',
            'dikirim',
            'diterima'
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(f[0].toUpperCase() + f.substring(1).replaceAll('_', ' ')),
                selected: _filterStatus == f,
                onSelected: (_) => setState(() => _filterStatus = f),
              ),
            ),
        ]),
      ),
      if (_cabangs.isNotEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: DropdownButtonFormField<String?>(
            value: _filterCabang,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Filter Cabang',
              isDense: true,
              prefixIcon: Icon(Icons.store),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Semua Cabang'),
              ),
              ..._cabangs.map((c) => DropdownMenuItem<String?>(
                    value: c['id']?.toString(),
                    child: Text(c['cabang_nama']?.toString() ?? c['username']?.toString() ?? '-'),
                  )),
            ],
            onChanged: (v) => setState(() => _filterCabang = v),
          ),
        ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: _filtered.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Tidak ada pesanan'))
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final o = _filtered[i];
                    final st = (o['status'] ?? '').toString().toLowerCase();
                    final paid = _isPaid(o);
                    final canConfirm = _canConfirm(o);
                    final id = o['id']?.toString() ?? '';

                    return SmoothListItem(index: i, child: Card(
                      margin: const EdgeInsets.only(bottom: 8),
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
                                        color: cs.outline, fontSize: 13)),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: paid
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  paid ? 'LUNAS' : 'BELUM BAYAR',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: paid
                                          ? Colors.green
                                          : Colors.orange),
                                ),
                              ),
                            ]),
                            Text(
                                '${o['jumlah_item'] ?? 0} item | ${formatCurrency(o['total_harga'] ?? 0)}',
                                style: TextStyle(
                                    color: cs.outline, fontSize: 13)),
                            if (canConfirm) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (_actionId == id)
                                    const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    )
                                  else ...[
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: cs.error,
                                        side: BorderSide(color: cs.error),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () => _reject(o),
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text('Tolak'),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      style: FilledButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () => _approve(o),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Konfirmasi'),
                                    ),
                                  ],
                                ],
                              ),
                            ] else if (st == 'pending') ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Menunggu pembayaran cabang',
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ));
                  },
                ),
        ),
      ),
    ]);
  }
}
