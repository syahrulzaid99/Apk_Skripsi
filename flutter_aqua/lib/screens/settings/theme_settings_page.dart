import 'package:flutter/material.dart';
import '../../config/theme_provider.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  late ThemeProvider _provider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _provider = ThemeProviderScope.of(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Tema')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _provider.isDark ? Icons.dark_mode : Icons.light_mode,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode Gelap',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _provider.isDark
                              ? 'Tema gelap sedang aktif'
                              : 'Tema terang sedang aktif',
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _provider.isDark,
                    onChanged: (v) => _provider.setMode(
                      v ? ThemeMode.dark : ThemeMode.light,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pilih tema yang nyaman untuk pengalaman menggunakan aplikasi. Perubahan akan diterapkan secara otomatis.',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class ThemeProviderScope extends InheritedWidget {
  final ThemeProvider provider;

  const ThemeProviderScope({
    super.key,
    required this.provider,
    required super.child,
  });

  static ThemeProvider of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeProviderScope>();
    assert(scope != null, 'ThemeProviderScope tidak ditemukan di widget tree');
    return scope!.provider;
  }

  @override
  bool updateShouldNotify(ThemeProviderScope oldWidget) =>
      provider != oldWidget.provider;
}
