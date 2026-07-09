import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../cabang/cabang_order_page.dart'; // PaymentWebViewPage

class SalesCreateOrderPage extends StatefulWidget {
  const SalesCreateOrderPage({super.key});

  @override
  State<SalesCreateOrderPage> createState() => _SalesCreateOrderPageState();
}

class _SalesCreateOrderPageState extends State<SalesCreateOrderPage>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _cabangs = [];
  final Map<String, int> _cart = {};
  String? _selectedCabangId;
  final _ketCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  bool _loading = false, _sending = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchCabangs();
  }

  @override
  void dispose() {
    _ketCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _fetchProducts() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getProducts();
      if (res.statusCode == 200) {
        _products = (jsonDecode(res.body)['products'] as List? ?? [])
            .cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    finally { if (mounted) setState(() => _loading = false); }
  }

  Future<void> _fetchCabangs() async {
    try {
      // Ambil daftar cabang dari orders yang sudah ada
      final res = await ApiClient.getSalesOrders();
      if (res.statusCode == 200) {
        final orders = (jsonDecode(res.body)['orders'] as List? ?? [])
            .cast<Map<String, dynamic>>();
        final seen = <String>{};
        final list = <Map<String, dynamic>>[];
        for (final o in orders) {
          final cid = o['cabang_id']?.toString();
          if (cid != null && cid.isNotEmpty && !seen.contains(cid)) {
            seen.add(cid);
            list
                .add({'id': cid, 'username': o['cabang_username'] ?? cid});
          }
        }
        setState(() => _cabangs = list);
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _products;
    return _products.where((p) {
      return (p['nama_produk'] ?? '')
              .toString()
              .toLowerCase()
              .contains(q) ||
          (p['sku'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  int get _totalItems => _cart.values.fold(0, (a, b) => a + b);
  num get _totalHarga => _cart.entries.fold<num>(0, (sum, e) {
        final p = _products.firstWhere(
            (p) => p['id'] == e.key,
            orElse: () => <String, dynamic>{});
        return sum + ((p['harga_jual'] ?? 0) * e.value);
      });

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) { _snack('Pilih minimal 1 produk'); return; }
    if (_selectedCabangId == null || _selectedCabangId!.isEmpty) {
      _snack('Pilih cabang tujuan!');
      return;
    }

    setState(() => _sending = true);
    try {
      final items = _cart.entries
          .map((e) => {'product_id': e.key, 'qty': e.value})
          .toList();

      final res = await ApiClient.createSalesOrder(
        items: items,
        cabangId: _selectedCabangId!,
        keterangan: _ketCtrl.text.trim(),
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        _snack('✅ Order ${body['kode_order']} berhasil!');
        _cart.clear();
        _ketCtrl.clear();
        setState(() => _selectedCabangId = null);
        final paymentUrl = body['payment_url']?.toString();
        if (paymentUrl != null && paymentUrl.isNotEmpty && mounted) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PaymentWebViewPage(
                paymentUrl: paymentUrl,
                orderId: body['id']?.toString() ?? ''),
          ));
        }
      } else {
        try {
          final errBody = jsonDecode(res.body);
          _snack(
              errBody['message']?.toString() ?? 'Gagal (${res.statusCode})');
        } catch (_) {
          _snack('Gagal membuat order (${res.statusCode})');
        }
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    return Column(children: [
      // Cabang Selector
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        color: cs.surfaceContainerLow,
        child: Row(children: [
          Icon(Icons.store, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedCabangId,
              decoration: const InputDecoration(
                  labelText: 'Pilih Cabang Tujuan', isDense: true),
              items: _cabangs
                  .map((c) => DropdownMenuItem(
                        value: c['id']?.toString() ?? '',
                        child: Text(c['username']?.toString() ?? '-'),
                      ))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedCabangId = v),
              validator: (v) =>
                  v == null || v.isEmpty ? 'Wajib' : null,
            ),
          ),
        ]),
      ),
      // Search
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Cari produk...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() {});
                    })
                : null,
          ),
        ),
      ),
      // Product list
      Expanded(
        child: _loading && _products.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filtered.length + 1,
                itemBuilder: (_, i) {
                  if (i == _filtered.length)
                    return const SizedBox(height: 120);
                  final p = _filtered[i];
                  final id = p['id'] as String;
                  final qty = _cart[id] ?? 0;
                  final stok = p['stok'] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(children: [
                        ProductThumb(
                            url: p['gambar_url']?.toString() ?? ''),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(p['nama_produk'] ?? '-',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14)),
                              Text(
                                'SKU: ${p['sku'] ?? ''} | ${formatCurrency(p['harga_jual'] ?? 0)} / ${p['satuan'] ?? ''}',
                                style: TextStyle(
                                    fontSize: 12, color: cs.outline),
                              ),
                              Text('Stok: $stok',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: stok <= 0
                                          ? Colors.red
                                          : Colors.green)),
                            ],
                          ),
                        ),
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          if (qty > 0)
                            IconButton(
                              icon: Icon(Icons.remove_circle,
                                  color: cs.error),
                              onPressed: () => setState(() {
                                if (qty <= 1) {
                                  _cart.remove(id);
                                } else {
                                  _cart[id] = qty - 1;
                                }
                              }),
                            ),
                          if (qty > 0)
                            Text('$qty',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16)),
                          IconButton(
                            icon: Icon(Icons.add_circle,
                                color: stok <= 0
                                    ? Colors.grey
                                    : cs.primary),
                            onPressed: stok <= 0
                                ? null
                                : () => setState(() {
                                      _cart[id] = qty + 1;
                                    }),
                          ),
                        ]),
                      ]),
                    ),
                  );
                }),
      ),
      // Bottom bar
      if (_cart.isNotEmpty)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            border: Border(
                top: BorderSide(color: cs.outlineVariant)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: _ketCtrl,
              decoration: const InputDecoration(
                  labelText: 'Keterangan (opsional)',
                  prefixIcon: Icon(Icons.note_alt),
                  isDense: true),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_totalItems produk',
                        style: const TextStyle(fontSize: 13)),
                    Text(formatCurrency(_totalHarga),
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: cs.primary)),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _sending ? null : _submitOrder,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2))
                    : const Icon(Icons.send),
                label: const Text('Buat Pesanan'),
              ),
            ]),
          ]),
        ),
    ]);
  }
}
