import 'package:flutter/material.dart';
import 'cabang_stock_page.dart';
import 'cabang_order_page.dart';

class CabangStokOrderPage extends StatefulWidget {
  const CabangStokOrderPage({super.key});

  @override
  State<CabangStokOrderPage> createState() => _CabangStokOrderPageState();
}

class _CabangStokOrderPageState extends State<CabangStokOrderPage>
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
        Tab(icon: Icon(Icons.inventory_2), text: 'Stok Masuk'),
        Tab(icon: Icon(Icons.shopping_cart), text: 'Order'),
      ]),
      Expanded(child: TabBarView(controller: _tabCtrl, children: const [
        CabangStockPage(),
        CabangOrderPage(),
      ])),
    ]);
  }
}
