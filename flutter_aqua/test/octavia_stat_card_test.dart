import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_aqua_stock_1/widgets/shared.dart';

void main() {
  Future<void> pumpGrid(WidgetTester tester, {required double extent}) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: extent,
          ),
          children: const [
            OctaviaStatCard(
                icon: Icons.inventory_2,
                label: 'Total pesanan',
                value: '4',
                color: Colors.blue),
            OctaviaStatCard(
                icon: Icons.route,
                label: 'Dalam proses',
                value: '2',
                color: Colors.orange),
            OctaviaStatCard(
                icon: Icons.check_circle,
                label: 'Selesai diterima',
                value: '1',
                color: Colors.green),
            OctaviaStatCard(
                icon: Icons.cancel,
                label: 'Ditolak',
                value: '1',
                color: Colors.red),
          ],
        ),
      ),
    ));
    await tester.pump();
  }

  testWidgets('OctaviaStatCard tidak overflow di sel grid 140px (kasus asli)',
      (tester) async {
    await pumpGrid(tester, extent: 140);
    expect(tester.takeException(), isNull,
        reason: 'Overflow muncul di sel grid 140px');
  });

  testWidgets('OctaviaStatCard tidak overflow di sel sangat pendek (90px)',
      (tester) async {
    await pumpGrid(tester, extent: 90);
    expect(tester.takeException(), isNull,
        reason: 'Overflow muncul di sel 90px (harus di-scale-down FittedBox)');
  });
}
