import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../widgets/smooth_list_item.dart';
import '../cabang/cabang_order_page.dart';

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
  String? _payingId;

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

  bool _isUnpaid(Map<String, dynamic> o) {
    final ps = (o['payment_status'] ?? 'pending').toString().toLowerCase();
    final st = (o['status'] ?? '').toString().toLowerCase();
    return st == 'pending' &&
        ps != 'settlement' &&
        ps != 'capture';
  }

  Future<void> _retryPay(Map<String, dynamic> o) async {
    final id = o['id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _payingId = id);
    try {
      final res = await ApiClient.salesPayOrder(id);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final url = body['payment_url']?.toString();
        if (url != null && url.isNotEmpty && mounted) {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PaymentWebViewPage(
                paymentUrl: url, orderId: id),
          ));
          _fetch();
        } else {
          _snack('Tidak ada payment URL');
        }
      } else {
        _snack('Gagal memuat pembayaran (${res.statusCode})');
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _payingId = null);
    }
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
                    final paid =
                        (o['payment_status'] ?? '').toString().toLowerCase() ==
                            'settlement';
                    final unpaid = _isUnpaid(o);
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
                              Text(
                                  'Cabang: ${_displayName(o)}',
                                  style: TextStyle(
                                      color: cs.outline, fontSize: 13)),
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
                            if (unpaid)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _payingId == id
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : FilledButton.icon(
                                          onPressed: () => _retryPay(o),
                                          icon: const Icon(Icons.payment),
                                          label: const Text('Bayar'),
                                        ),
                                ),
                              ),
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
