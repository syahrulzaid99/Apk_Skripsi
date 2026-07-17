import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/api_config.dart';
import '../../config/theme_provider.dart';
import 'theme_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late TextEditingController _urlCtrl;
  bool _loading = false;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: ApiConfig.activeUrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _themeProvider = ThemeProviderScope.of(context);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }
  }

  Future<void> _saveUrl() async {
    final newUrl = _urlCtrl.text.trim();
    if (newUrl.isEmpty) {
      _snack('URL tidak boleh kosong');
      return;
    }

    if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
      _snack('URL harus dimulai dengan http:// atau https://');
      return;
    }

    setState(() => _loading = true);

    try {
      await ApiConfig.setBaseUrl(newUrl);
      _snack('Server URL berhasil disimpan');
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _resetToDefault() async {
    setState(() => _loading = true);

    try {
      await ApiConfig.resetToDefault();
      _urlCtrl.text = ApiConfig.defaultBaseUrl;
      _snack('Server URL direset ke default');
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cara Menggunakan'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Opsi 1 — Hostname (.local), untuk HP & PC di WiFi SAMA:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Default sudah http://SYAHRUL.local:3000'),
              Text('• Otomatis ke IP PC, tidak perlu ganti IP'),
              Text('• Syarat: HP & PC di WiFi yang sama'),
              SizedBox(height: 12),
              Text(
                'Opsi 2 — Tunnel (localtunnel/ngrok), lintas jaringan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Jalankan start-tunnel.bat di folder web_aqua'),
              Text('• Salin URL https://xxxx.loca.lt yang muncul'),
              Text('• Tempel di field "Server URL" bawah ini > Simpan'),
              Text('• Bisa akses dari 4G/5G (tidak perlu WiFi sama)'),
              SizedBox(height: 12),
              Text(
                'Opsi 3 — Manual IP (cadangan):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• CMD ketik ipconfig, lihat IPv4 Address'),
              Text('• Format: http://<IP>:3000'),
              SizedBox(height: 12),
              Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Port default backend: 3000'),
              Text('• URL disimpan otomatis di app (SharedPreferences)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Bantuan',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tampilan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                      color: cs.onSurfaceVariant,
                    ),
                    title: const Text('Mode Gelap'),
                    subtitle: Text(
                      _themeProvider.isDark ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    trailing: Switch(
                      value: _themeProvider.isDark,
                      onChanged: (v) => _themeProvider.setMode(
                        v ? ThemeMode.dark : ThemeMode.light,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: cs.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Konfigurasi Server Backend',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ubah URL server backend sesuai IP address komputer server. URL akan disimpan otomatis.',
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _urlCtrl,
            decoration: InputDecoration(
              labelText: 'Server URL',
              hintText: 'http://192.168.x.x:3000',
              prefixIcon: const Icon(Icons.dns),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.content_copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _urlCtrl.text));
                  _snack('URL disalin');
                },
                tooltip: 'Salin URL',
              ),
            ),
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saveUrl(),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _saveUrl,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Simpan'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _resetToDefault,
            icon: const Icon(Icons.restore),
            label: const Text('Reset ke Default'),
          ),
          const SizedBox(height: 24),
          Card(
            color: cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Saat Ini',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'URL Aktif: ',
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          ApiConfig.activeUrl,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Default: ${ApiConfig.defaultBaseUrl}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: cs.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: cs.onErrorContainer, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Catatan Penting',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Pastikan HP dan server terhubung ke WiFi yang sama\n'
                    '• Setelah ganti URL, restart app untuk memastikan perubahan berlaku\n'
                    '• URL disimpan di SharedPreferences dan persisten',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
