import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_page.dart';
import 'cabang_dashboard_page.dart';
import 'cabang_stock_page.dart';
import 'cabang_order_page.dart';
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

  String _getTitle() {
    switch (_idx) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Stok Masuk';
      case 3:
        return 'Order';
      case 4:
        return 'Profil';
      default:
        return 'Aqua Japan Cabang';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pages = [
      const CabangDashboardPage(),
      const CabangStockPage(),
      const SizedBox.shrink(),
      const CabangOrderPage(),
      const CabangProfilePage(),
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
              onPressed: _logout,
              icon: Icon(Icons.logout_rounded, size: 20, color: cs.onSurfaceVariant),
              tooltip: 'Keluar',
            ),
          ),
          const SizedBox(width: 8),
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
              onDestinationSelected: (i) {
                if (i == 2) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CabangScanPage()),
                  );
                } else {
                  setState(() => _idx = i);
                }
              },
              height: 64,
              backgroundColor: Colors.transparent,
              elevation: 0,
              shadowColor: Colors.transparent,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  selectedIcon: Icon(Icons.inventory_2),
                  label: 'Stok Masuk',
                ),
                NavigationDestination(
                  icon: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: OctaviaColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: OctaviaColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                    ),
                  ),
                  selectedIcon: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: OctaviaColors.primary,
                        boxShadow: [
                          BoxShadow(
                            color: OctaviaColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                    ),
                  ),
                  label: 'Scan',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.shopping_cart_outlined),
                  selectedIcon: Icon(Icons.shopping_cart),
                  label: 'Order',
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
      ),
    );
  }
}
