import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart';
import '../../config/api_config.dart';

class CabangOrderPage extends StatefulWidget {
  const CabangOrderPage({super.key});

  @override
  State<CabangOrderPage> createState() => _CabangOrderPageState();
}

class _CabangOrderPageState extends State<CabangOrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TabBar(controller: _tabCtrl, tabs: const [
        Tab(icon: Icon(Icons.add_shopping_cart), text: 'Buat Order'),
        Tab(icon: Icon(Icons.history), text: 'Riwayat'),
      ]),
      Expanded(child: TabBarView(controller: _tabCtrl, children: [
        _CreateOrderTab(onCreated: () => _tabCtrl.animateTo(1)),
        const _OrderHistoryTab(),
      ])),
    ]);
  }
}

class _CreateOrderTab extends StatefulWidget {
  final VoidCallback? onCreated;
  const _CreateOrderTab({this.onCreated});

  @override
  State<_CreateOrderTab> createState() => _CreateOrderTabState();
}

class _CreateOrderTabState extends State<_CreateOrderTab> with AutomaticKeepAliveClientMixin {
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
      final res = await ApiClient.getProducts();
      if (res.statusCode == 200) {
        _products = (jsonDecode(res.body)['products'] as List? ?? []).cast<Map<String, dynamic>>();
      } else _snack('Gagal memuat produk');
    } catch (_) { _snack('Gagal terhubung ke server'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _products;
    return _products.where((p) {
      return (p['nama_produk'] ?? '').toString().toLowerCase().contains(q) ||
          (p['sku'] ?? '').toString().toLowerCase().contains(q);
    }).toList();
  }

  int get _totalItems => _cart.values.fold(0, (a, b) => a + b);
  num get _totalHarga => _cart.entries.fold<num>(0, (sum, e) {
    final p = _products.firstWhere((p) => p['id'] == e.key, orElse: () => <String, dynamic>{});
    return sum + ((p['harga_jual'] ?? 0) * e.value);
  });

  Future<void> _submitOrder() async {
    if (_cart.isEmpty) { _snack('Pilih minimal 1 produk'); return; }
    setState(() => _sending = true);
    try {
      final items = _cart.entries.map((e) => {'product_id': e.key, 'qty': e.value}).toList();
      final res = await ApiClient.createOrder(items: items, keterangan: _ketCtrl.text.trim());
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        _snack('✅ Order ${body['kode_order']} berhasil!');
        _cart.clear(); _ketCtrl.clear();
        setState(() {});
        widget.onCreated?.call();
        final paymentUrl = body['payment_url']?.toString();
        if (paymentUrl != null && paymentUrl.isNotEmpty && mounted) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PaymentWebViewPage(paymentUrl: paymentUrl, orderId: body['id']?.toString() ?? ''),
          ));
        }
      } else _snack('Gagal membuat order (${res.statusCode})');
    } catch (e) { _snack('Error: $e'); }
    finally { if (mounted) setState(() => _sending = false); }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    if (_loading && _products.isEmpty) return const Center(child: CircularProgressIndicator());

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Cari produk...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchCtrl.text.isNotEmpty
                ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchCtrl.clear(); setState(() {}); })
                : null,
          ),
        ),
      ),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filtered.length + 1,
        itemBuilder: (_, i) {
          if (i == _filtered.length) return const SizedBox(height: 120);
          final p = _filtered[i];
          final id = p['id'] as String;
          final nama = p['nama_produk'] ?? '-';
          final harga = p['harga_jual'] ?? 0;
          final stok = p['stok'] ?? 0;
          final img = absolutizeUrl(p['gambar_url']?.toString());
          final qty = _cart[id] ?? 0;

          return Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              ProductThumb(url: img),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(nama, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                if (p['sku'] != null) Text('SKU: ${p['sku']}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                Text('${formatCurrency(harga)} / ${p['satuan'] ?? ''}', style: TextStyle(fontSize: 12, color: cs.primary)),
                Text('Stok: $stok', style: TextStyle(fontSize: 12, color: stok <= 0 ? Colors.red : Colors.black45)),
              ])),
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (qty > 0) IconButton(icon: Icon(Icons.remove_circle, color: cs.error), onPressed: () => setState(() {
                  if (qty <= 1) _cart.remove(id); else _cart[id] = qty - 1;
                })),
                if (qty > 0) Text('$qty', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                IconButton(
                  icon: Icon(Icons.add_circle, color: stok <= 0 ? Colors.grey : cs.primary),
                  onPressed: stok <= 0 ? null : () => setState(() => _cart[id] = qty + 1),
                ),
              ]),
            ]),
          ));
        },
      )),
      if (_cart.isNotEmpty) Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: cs.surfaceContainerLow, border: Border(top: BorderSide(color: cs.outlineVariant))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _ketCtrl, decoration: const InputDecoration(labelText: 'Keterangan (opsional)', prefixIcon: Icon(Icons.note_alt), isDense: true)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$_totalItems produk', style: const TextStyle(fontSize: 13)),
              Text(formatCurrency(_totalHarga), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: cs.primary)),
            ])),
            FilledButton.icon(
              onPressed: _sending ? null : _submitOrder,
              icon: _sending ? const SizedBox(width:18, height:18, child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.send),
              label: const Text('Kirim Order'),
            ),
          ]),
        ]),
      ),
    ]);
  }
}

class _OrderHistoryTab extends StatefulWidget {
  const _OrderHistoryTab();

  @override
  State<_OrderHistoryTab> createState() => _OrderHistoryTabState();
}

class _OrderHistoryTabState extends State<_OrderHistoryTab> with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() { super.initState(); _fetch(); }

  void _snack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getOrders();
      if (res.statusCode == 200) {
        _orders = (jsonDecode(res.body)['orders'] as List? ?? []).cast<Map<String, dynamic>>();
      } else _snack('Gagal memuat riwayat');
    } catch (_) { _snack('Gagal terhubung ke server'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'diproses': case 'approved_sales': case 'approved_admin': return Colors.blue;
      case 'dipaket': case 'dikirim': return Colors.indigo;
      case 'diterima': case 'selesai': return Colors.green;
      case 'ditolak': case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'pending': return 'Menunggu';
      case 'approved_sales': return 'Disetujui Sales';
      case 'approved_admin': return 'Diverifikasi';
      case 'dipaket': return 'Dikemas';
      case 'diproses': return 'Diproses';
      case 'dikirim': return 'Dikirim';
      case 'diterima': return 'Diterima';
      case 'selesai': return 'Selesai';
      case 'rejected': case 'ditolak': return 'Ditolak';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    if (_loading && _orders.isEmpty) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: _fetch,
      child: _orders.isEmpty
          ? ListView(children: const [SizedBox(height: 80), Center(child: Column(children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.black26),
              SizedBox(height: 12), Text('Belum ada order', style: TextStyle(color: Colors.black45)),
            ]))])
          : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _orders.length, itemBuilder: (_, i) {
              final o = _orders[i];
              final kode = o['kode_order'] ?? '-';
              final status = (o['status'] ?? 'pending').toString();
              final total = o['total_harga'] ?? 0;
              final items = (o['items'] as List? ?? []);
              final ket = o['keterangan'] ?? '';

              return Card(margin: const EdgeInsets.only(bottom: 10), child: ExpansionTile(
                title: Text(kode, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                subtitle: Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _statusColor(status).withValues(alpha: 0.4)),
                    ),
                    child: Text(_statusLabel(status), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _statusColor(status))),
                  ),
                  const Spacer(),
                  Text(formatCurrency(total), style: TextStyle(fontWeight: FontWeight.w800, color: cs.primary)),
                ]),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  if (ket.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [const Icon(Icons.note_alt, size: 16, color: Colors.black45), const SizedBox(width: 6), Expanded(child: Text(ket))])),
                  ...items.map((it) {
                    final item = Map<String, dynamic>.from(it as Map);
                    return Padding(padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Expanded(child: Text(item['nama_produk'] ?? '-', style: const TextStyle(fontSize: 13))),
                        Text('x${item['qty']}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        const SizedBox(width: 12),
                        SizedBox(width: 90, child: Text(formatCurrency(item['subtotal'] ?? 0), textAlign: TextAlign.end, style: const TextStyle(fontSize: 13))),
                      ]));
                  }),
                ],
              ));
            }),
    );
  }
}

// ==================== PAYMENT WEBVIEW ====================

class PaymentWebViewPage extends StatefulWidget {
  final String paymentUrl;
  final String orderId;
  const PaymentWebViewPage({super.key, required this.paymentUrl, required this.orderId});

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _statusPembayaran = '';

  static const _successKeywords = ['status=success', 'transaction_status=settlement', 'transaction_status=capture', '/finish'];
  static const _pendingKeywords = ['status=pending', 'transaction_status=pending'];
  static const _failedKeywords = ['status=failure', 'status=error', 'transaction_status=deny', 'transaction_status=cancel', 'transaction_status=expire'];

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _isLoading = true),
        onPageFinished: (url) { setState(() => _isLoading = false); _checkPaymentStatus(url); },
        onNavigationRequest: (req) { _checkPaymentStatus(req.url); return NavigationDecision.navigate; },
      ))
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkPaymentStatus(String url) {
    final lower = url.toLowerCase();
    if (_successKeywords.any((k) => lower.contains(k))) _onPaymentResult('success');
    else if (_pendingKeywords.any((k) => lower.contains(k))) _onPaymentResult('pending');
    else if (_failedKeywords.any((k) => lower.contains(k))) _onPaymentResult('failed');
  }

  void _onPaymentResult(String status) {
    if (_statusPembayaran == status) return;
    _statusPembayaran = status;
    if (status == 'success') { ApiClient.confirmPayment(widget.orderId); }

    String pesan; IconData ikon; Color warna;
    switch (status) {
      case 'success': pesan = 'Pembayaran berhasil!'; ikon = Icons.check_circle_rounded; warna = Colors.green; break;
      case 'pending': pesan = 'Pembayaran sedang diproses.'; ikon = Icons.access_time_rounded; warna = Colors.orange; break;
      default: pesan = 'Pembayaran gagal atau dibatalkan.'; ikon = Icons.cancel_rounded; warna = Colors.red;
    }

    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
      icon: Icon(ikon, color: warna, size: 48),
      title: Text(status == 'success' ? 'Berhasil' : status == 'pending' ? 'Menunggu' : 'Gagal'),
      content: Text(pesan, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [FilledButton.icon(
        onPressed: () { Navigator.of(context)..pop()..pop(); },
        icon: const Icon(Icons.arrow_back), label: const Text('Kembali'),
      )],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'), centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), tooltip: 'Tutup', onPressed: () => Navigator.of(context).pop()),
        actions: [_isLoading ? const Padding(padding: EdgeInsets.all(14), child: SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth:2))) : const SizedBox()],
      ),
      body: Stack(children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ]),
    );
  }
}
