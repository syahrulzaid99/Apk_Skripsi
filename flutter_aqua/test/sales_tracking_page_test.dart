import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aqua_stock_1/screens/sales/sales_tracking_page.dart';

Map<String, dynamic> _order(String kode, String status,
    {String resi = '', List<Map<String, dynamic>>? history}) {
  return {
    'id': kode,
    'kode_order': kode,
    'cabang_id': 'c1',
    'cabang_username': 'Cabang Satu',
    'cabang_nama': 'Cabang Satu',
    'status': status,
    'payment_status': 'settlement',
    'total_harga': 1500000,
    'jumlah_item': 2,
    'kode_pengiriman': resi,
    'shipment_id': resi.isNotEmpty ? 'sh1' : '',
    'createdAt': {'_seconds': 1700000000},
    'approved_sales_at': {'_seconds': 1700000100},
    'approved_admin_at': {'_seconds': 1700000200},
    'packed_at': {'_seconds': 1700000300},
    'dikirim_at': {'_seconds': 1700000400},
    'diterima_at': null,
    'diterima_oleh': '',
    'rejected_at': null,
    'rejection_reason': '',
    'items': [
      {'nama_produk': 'Aqua 600ml', 'qty': 24, 'harga': 5000},
      {'nama_produk': 'Aqua 1500ml', 'qty': 12, 'harga': 10000},
    ],
    'history': history ?? [],
  };
}

void main() {
  // Urutan diatur agar kartu dengan stepper beda rank (dikirim=4, pending=0,
  // rejected=-1) tampil di viewport pertama pada lebar 360dp.
  final orders = [
    _order('ORD-T1', 'dikirim',
        resi: 'RS-2026-001',
        history: [
          {
            'status': 'pending',
            'by_username': 'Cabang Satu',
            'at': {'_seconds': 1700000000},
            'note': ''
          },
          {
            'status': 'approved_sales',
            'by_username': 'Sales A',
            'at': {'_seconds': 1700000100},
            'note': ''
          },
          {
            'status': 'approved_admin',
            'by_username': 'Admin',
            'at': {'_seconds': 1700000200},
            'note': ''
          },
          {
            'status': 'dipaket',
            'by_username': 'Gudang',
            'at': {'_seconds': 1700000300},
            'note': ''
          },
          {
            'status': 'dikirim',
            'by_username': 'Gudang',
            'at': {'_seconds': 1700000400},
            'note': 'Shipment: RS-2026-001'
          },
        ]),
    _order('ORD-T5', 'pending'),
    _order('ORD-T4', 'rejected',
        history: [
          {
            'status': 'rejected',
            'by_username': 'Sales A',
            'at': {'_seconds': 1700000500},
            'note': 'Melebihi plafon'
          },
        ]),
    _order('ORD-T3', 'approved_sales'),
    _order('ORD-T2', 'diterima', resi: 'RS-2026-002'),
  ];

  Future<void> pump(WidgetTester tester,
      {double width = 360, double scale = 1.0}) async {
    tester.view.physicalSize = Size(width * 3, 800 * 3);
    tester.view.devicePixelRatio = 3.0;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SalesTrackingPage(initialOrders: orders)),
    ));
    // pumpAndSettle: flush animasi masuk SmoothListItem (Timer) supaya tidak
    // tersisa "Timer still pending" saat test selesai.
    await tester.pumpAndSettle();
  }

  testWidgets('list & KPI tanpa overflow (360dp, skala 1.0)', (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('ORD-T1'), findsOneWidget);
    expect(find.text('ORD-T5'), findsOneWidget);
  });

  testWidgets('list & KPI tanpa overflow (320dp, skala 1.3)', (tester) async {
    await pump(tester, width: 320, scale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('list & KPI tanpa overflow (411dp, skala 2.0)', (tester) async {
    await pump(tester, width: 411, scale: 2.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scroll seluruh list tanpa overflow', (tester) async {
    await pump(tester);
    final listFinder = find.byType(ListView);
    for (var i = 0; i < 4; i++) {
      await tester.drag(listFinder.first, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'Overflow muncul saat scroll posisi ke-$i');
    }
    // Pastikan kartu paling bawah ikut ter-render
    expect(find.text('ORD-T2'), findsOneWidget);
  });

  testWidgets('bottom sheet detail tanpa overflow', (tester) async {
    await pump(tester);
    await tester.tap(find.text('ORD-T1'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Progres status'), findsOneWidget);
    expect(find.text('Dikonfirmasi sales'), findsOneWidget);
  });

  testWidgets('kartu ditolak tampil tanpa overflow (skala 1.3)',
      (tester) async {
    await pump(tester, scale: 1.3);
    expect(find.text('Ditolak'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
