import 'package:flutter/material.dart';
import '../cabang/cabang_home.dart';
import '../sales/sales_home.dart';
import '../gudang/gudang_home.dart';
import '../../services/auth_service.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _hasToken;

  @override
  void initState() {
    super.initState();
    _hasToken = AuthService.hasToken();
  }

  Widget _buildByRole(String role) {
    switch (role) {
      case 'sales':
        return const SalesHomePage();
      case 'gudang':
        return const GudangHomePage();
      default:
        return const CabangHomePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasToken,
      builder: (_, snap) {
        if (!snap.hasData) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.water_drop_rounded,
                      size: 48,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4)),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        if (snap.data != true) {
          return const LoginPage();
        }

        // Check role for routing
        return FutureBuilder<String?>(
          future: AuthService.role(),
          builder: (_, roleSnap) {
            if (!roleSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return _buildByRole(roleSnap.data ?? 'cabang');
          },
        );
      },
    );
  }
}
