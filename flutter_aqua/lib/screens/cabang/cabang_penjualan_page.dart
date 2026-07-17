import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../widgets/smooth_list_item.dart';

class CabangPenjualanPage extends StatefulWidget {
  const CabangPenjualanPage({super.key});

  @override
  State<CabangPenjualanPage> createState() => _CabangPenjualanPageState();
}

class _CabangPenjualanPageState extends State<CabangPenjualanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TabBar(controller: _tabCtrl, tabs: const [
        Tab(icon: Icon(Icons.point_of_sale), text: 'Buat Penjualan'),
        Tab(icon: Icon(Icons.receipt_long), text: 'Riwayat'),
      ]),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        _CreateSaleTab(onCreated: () => _tabCtrl.animateTo(1)),
        const _SalesHistoryTab(),
      ])),
    ]);
  }
}

class _CreateSaleTab extends StatefulWidget {
  final VoidCallback? onCreated;
  const _CreateSaleTab({this.onCreated});

  @override
  State<_CreateSaleTab> createState() => _CreateSaleTabState();
}

class _CreateSaleTabState extends State<_CreateSaleTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _products = [];
  final Map<String, int> _cart = {};
  final _ketCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  bool _loading = false, _sending = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _fetchProducts(); }

  @override
  void dispose() { _ketCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  void _snack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  Future<void> _fetchProducts() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getBranchProducts();
      if (res.statusCode == 200) {
        _products = (jsonDecode(res.body)['products'] as List? ?? []).cast<Map<String, dynamic>>();
        _cart.clear();
      } else _snack('Gagal memuat stok cabang');
    } catch (_) { _snack('Gagal terhubung ke server'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _products;
    return _products.where((p) => (p['nama_produk'] ?? '').toString().toLowerCase().contains(q) ||
        (p['sku'] ?? '').toString().toLowerCase().contains(q)).toList();
  }

  int get _totalItems => _cart.values.fold(0, (a, b) => a + b);
  int get _totalHarga => _cart.entries.fold<int>(0, (sum, e) {
    final p = _products.firstWhere((p) => p['id'] == e.key, orElse: () => <String, dynamic>{});
    return sum + (toInt(p['harga_jual']) * e.value);
  });

  Future<void> _submitSale() async {
    if (_cart.isEmpty) { _snack('Pilih minimal 1 produk'); return; }
    setState(() => _sending = true);
    try {
      final items = _cart.entries.map((e) => {'product_id': e.key, 'qty': e.value}).toList();
      final res = await ApiClient.createSale(items: items, keterangan: _ketCtrl.text.trim(), totalBayar: _totalHarga);
      if (res.statusCode == 200) {
        _snack('✅ Penjualan berhasil!'); _cart.clear(); _ketCtrl.clear();
        setState(() {});
        widget.onCreated?.call();
      } else _snack('Gagal membuat penjualan');
    } catch (e) { _snack('Error: $e'); }
    finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    if (_loading && _products.isEmpty) return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ShimmerBox(width: double.infinity, height: 76, borderRadius: BorderRadius.circular(12)),
      ),
    );

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 8), child: TextField(
        controller: _searchCtrl,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: 'Cari produk...', prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchCtrl.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() {}); }) : null),
      )),
      Expanded(child: _products.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inventory_2, size: 64, color: cs.outline),
              const SizedBox(height: 8), Text('Belum ada stok tersedia', style: TextStyle(color: cs.outline))]))
          : RefreshIndicator(onRefresh: _fetchProducts, child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final p = _filtered[i];
                final pid = p['id']?.toString() ?? '';
                final stok = toInt(p['stok_tersedia']);
                final harga = toInt(p['harga_jual']);
                final qty = _cart[pid] ?? 0;

                return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(
                  padding: const EdgeInsets.all(12), child: Row(children: [
                    ProductThumb(url: p['gambar_url']?.toString() ?? ''),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(p['nama_produk'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text('${p['sku'] ?? ''} | ${p['satuan'] ?? ''}', style: TextStyle(fontSize: 12, color: cs.outline)),
                      Text(formatCurrency(harga), style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                      Text('Stok: $stok', style: TextStyle(fontSize: 12, color: stok <= 0 ? Colors.red : Colors.green)),
                    ])),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: qty <= 0 ? null : () => setState(() {
                        if (qty <= 1) _cart.remove(pid); else _cart[pid] = qty - 1;
                      })),
                      Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: qty >= stok ? null : () => setState(() => _cart[pid] = qty + 1)),
                    ]),
                  ]),
                ));
              },
            ))),
      if (_totalItems > 0) Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        decoration: BoxDecoration(color: cs.surfaceContainerLow, boxShadow: [BoxShadow(color: cs.shadow, blurRadius: 8, offset: const Offset(0, -2))]),
        child: SafeArea(top: false, child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('$_totalItems item', style: TextStyle(fontSize: 12, color: cs.outline)),
            Text(formatCurrency(_totalHarga), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.primary)),
          ])),
          FilledButton.icon(
            onPressed: _sending ? null : _submitSale,
            icon: _sending ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.sell),
            label: const Text('Buat Penjualan'),
          ),
        ])),
      ),
    ]);
  }
}

class _SalesHistoryTab extends StatefulWidget {
  const _SalesHistoryTab();

  @override
  State<_SalesHistoryTab> createState() => _SalesHistoryTabState();
}

class _SalesHistoryTabState extends State<_SalesHistoryTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _sales = [];
  bool _loading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _fetch(); }

  void _snack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getSales();
      if (res.statusCode == 200) {
        _sales = (jsonDecode(res.body)['sales'] as List? ?? []).cast<Map<String, dynamic>>();
      } else _snack('Gagal memuat riwayat');
    } catch (_) { _snack('Gagal terhubung ke server'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    if (_loading && _sales.isEmpty) return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => const ShimmerCard(),
    );

    return RefreshIndicator(onRefresh: _fetch, child: _sales.isEmpty
        ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.receipt_long, size: 64, color: cs.outline),
            const SizedBox(height: 8), Text('Belum ada penjualan', style: TextStyle(color: cs.outline))]))
        : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _sales.length, itemBuilder: (_, i) {
            final s = _sales[i];
            return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(
              padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(s['kode_penjualan'] ?? '-', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
                  const Spacer(),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Text('SELESAI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green))),
                ]),
                const SizedBox(height: 6),
                Text('${toInt(s['jumlah_item'])} item | ${formatCurrency(s['total_harga'])}', style: TextStyle(color: cs.outline, fontSize: 13)),
              ]),
            ));
          }),
    );
  }
}
