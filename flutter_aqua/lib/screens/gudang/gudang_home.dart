import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  String _getTitle() {
    switch (_idx) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Pengemasan';
      case 2:
        return 'Riwayat';
      default:
        return 'Gudang';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pages = [
      const GudangDashboardPage(),
      const GudangPackingPage(),
      const GudangShipmentsPage(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _getTitle(),
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.settings_outlined, size: 20, color: cs.onSurfaceVariant),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                );
              },
              tooltip: 'Pengaturan',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: _logout,
              icon: Icon(Icons.logout_rounded, size: 20, color: cs.onSurfaceVariant),
              tooltip: 'Keluar',
            ),
          ),
        ],
      ),
      body: IndexedStack(index: _idx, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: NavigationBar(
              selectedIndex: _idx,
              onDestinationSelected: (i) => setState(() => _idx = i),
              height: 64,
              backgroundColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
                NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Pengemasan'),
                NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Riwayat'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
