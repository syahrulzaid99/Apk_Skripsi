import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import 'cabang_dashboard_page.dart';
import 'cabang_stok_order_page.dart';
import 'cabang_penjualan_page.dart';
import 'cabang_profile_page.dart';
import 'cabang_scan_page.dart';

class CabangHomePage extends StatefulWidget {
  const CabangHomePage({super.key});

  @override
  State<CabangHomePage> createState() => _CabangHomePageState();
}

class _CabangHomePageState extends State<CabangHomePage> {
  int _idx = 0;

  Future<void> _logout() async {
    await AuthService.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const CabangDashboardPage(),
      const CabangStokOrderPage(),
      const SizedBox.shrink(),
      const CabangPenjualanPage(),
      const CabangProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aqua Japan Cabang'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: IndexedStack(index: _idx, children: pages),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: NavigationBar(
            selectedIndex: _idx,
            onDestinationSelected: (i) {
              if (i == 2) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CabangScanPage()),
                );
              } else {
                setState(() => _idx = i);
              }
            },
            height: 72,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              const NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: 'Stok & Order',
              ),
              NavigationDestination(
                icon: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0099DD),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  ),
                ),
                selectedIcon: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 48, height: 48,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF0099DD),
                    ),
                    child: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  ),
                ),
                label: 'Scan',
              ),
              const NavigationDestination(
                icon: Icon(Icons.sell_outlined),
                selectedIcon: Icon(Icons.sell),
                label: 'Penjualan',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
