import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aqua_stock_1/screens/sales/sales_report_page.dart';

Map<String, dynamic> _month(int total, String label) =>
    {'label': label, 'total': total};

void main() {
  // Data meniru screenshot: 2 kartu cabang dengan mini chart bulanan.
  final report = <String, dynamic>{
    'summary': {
      'totalPendapatan': 66559600,
      'totalOrders': 3,
      'totalItem': 4,
    },
    'monthly': [
      _month(10000000, 'Jan 2026'),
      _month(20000000, 'Feb 2026'),
      _month(30000000, 'Mar 2026'),
    ],
    'branches': [
      {
        'nama_cabang': 'CV.Sanyota',
        'username': 'CV.Sanyota',
        'kota': 'Pinrang',
        'provinsi': 'Sulawesi Selatan',
        'totalPendapatan': 40219800,
        'totalOrders': 1,
        'totalItem': 2,
        'monthly': [
          _month(12000000, 'Jan 2026'),
          _month(18000000, 'Feb 2026'),
          _month(40219800, 'Mar 2026'),
        ],
      },
      {
        'nama_cabang': 'Pinrang',
        'username': 'Pinrang',
        'kota': 'Pinrang',
        'provinsi': 'Sulawesi Selatan',
        'totalPendapatan': 26339800,
        'totalOrders': 2,
        'totalItem': 2,
        'monthly': [
          _month(8000000, 'Jan 2026'),
          _month(10000000, 'Feb 2026'),
          _month(26339800, 'Mar 2026'),
        ],
      },
    ],
    'recentOrders': [
      {
        'kode_order': 'ORD-9001',
        'status': 'dikirim',
        'cabang_username': 'CV.Sanyota',
        'jumlah_item': 2,
        'total_harga': 40219800,
        'createdAt': {'_seconds': 1700000000},
      },
    ],
  };

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
      home: Scaffold(body: SalesReportPage(initialReport: report)),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('laporan: kartu cabang + mini chart tanpa overflow (360dp, 1.0)',
      (tester) async {
    await pump(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('CV.Sanyota'), findsOneWidget);
    expect(find.text('Pinrang'), findsWidgets);
  });

  testWidgets('laporan tanpa overflow (320dp, skala 1.3)', (tester) async {
    await pump(tester, width: 320, scale: 1.3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('laporan tanpa overflow (411dp, skala 2.0)', (tester) async {
    await pump(tester, width: 411, scale: 2.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('laporan: scroll seluruh halaman tanpa overflow', (tester) async {
    await pump(tester);
    final listFinder = find.byType(ListView);
    for (var i = 0; i < 4; i++) {
      await tester.drag(listFinder.first, const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: 'Overflow muncul saat scroll posisi ke-$i');
    }
    expect(find.text('ORD-9001'), findsOneWidget);
  });
}
