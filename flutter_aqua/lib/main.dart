import 'package:flutter/material.dart';
import 'config/api_config.dart';
import 'config/theme.dart';
import 'config/theme_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/settings/theme_settings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();
  final themeProvider = ThemeProvider();
  await themeProvider.load();
  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return ThemeProviderScope(
      provider: themeProvider,
      child: ListenableBuilder(
        listenable: themeProvider,
        builder: (context, _) {
          return MaterialApp(
            title: 'Aqua Japan',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeProvider.mode,
            home: const AuthGate(),
            // Semua navigasi default pakai transisi smooth
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: const _SmoothScrollBehavior(),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}

/// Custom scroll behavior: bouncing physics di iOS-style, smooth glow di Android
class _SmoothScrollBehavior extends ScrollBehavior {
  const _SmoothScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}
