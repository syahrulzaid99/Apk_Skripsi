import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import '../settings/settings_page.dart';
import 'gudang_dashboard_page.dart';
import 'gudang_packing_page.dart';
import 'gudang_shipments_page.dart';

class GudangHomePage extends StatefulWidget {
  const GudangHomePage({super.key});

  @override
  State<GudangHomePage> createState() => _GudangHomePageState();
}

class _GudangHomePageState extends State<GudangHomePage> {
  int _idx = 0;

  Future<void> _logout() async {
    await AuthService.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const GudangDashboardPage(),
      const GudangPackingPage(),
      const GudangShipmentsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gudang - Aqua Japan'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
            tooltip: 'Pengaturan',
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: IndexedStack(index: _idx, children: pages),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: NavigationBar(
          selectedIndex: _idx,
          onDestinationSelected: (i) => setState(() => _idx = i),
          height: 72,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
            NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Pengemasan'),
            NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Riwayat'),
          ],
        ),
      ),
    );
  }
}
