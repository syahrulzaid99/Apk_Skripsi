import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../config/theme_provider.dart';
import '../../widgets/shared.dart';
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
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showHelpDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: OctaviaColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.help_outline, size: 16, color: OctaviaColors.primary),
          ),
          const SizedBox(width: 10),
          const Text('Cara Menggunakan'),
        ]),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Opsi 1 — Hostname (.local):',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              Text('• Default: http://SYAHRUL.local:3000',
                  style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
              Text('• Otomatis ke IP PC, tidak perlu ganti IP',
                  style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
              Text('• Syarat: HP & PC di WiFi yang sama',
                  style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              Text('Opsi 2 — Tunnel (localtunnel/ngrok):',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              Text('• Jalankan start-tunnel.bat di folder web_aqua',
                  style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
              Text('• Salin URL https://xxxx.loca.lt yang muncul',
                  style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
              Text('• Tempel di field "Server URL" > Simpan',
                  style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              Text('Opsi 3 — Manual IP:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              Text('• CMD: ipconfig, lihat IPv4 Address',
                  style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
              Text('• Format: http://<IP>:3000',
                  style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
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
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Theme section ──
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(
                    icon: Icons.palette_outlined,
                    title: 'Tampilan',
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: OctaviaColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _themeProvider.isDark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: OctaviaColors.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      'Mode Gelap',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      _themeProvider.isDark ? 'Aktif' : 'Nonaktif',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
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

          // ── Server config section ──
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(
                    icon: Icons.dns,
                    title: 'Konfigurasi Server',
                    trailing: IconButton(
                      icon: Icon(Icons.help_outline,
                          size: 18, color: cs.onSurfaceVariant),
                      onPressed: _showHelpDialog,
                      tooltip: 'Bantuan',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ubah URL server backend sesuai IP address komputer server.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _urlCtrl,
                    decoration: InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'http://192.168.x.x:3000',
                      prefixIcon: const Icon(Icons.link, size: 18),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.content_copy, size: 18),
                        onPressed: () {
                          Clipboard.setData(
                              ClipboardData(text: _urlCtrl.text));
                          _snack('URL disalin');
                        },
                        tooltip: 'Salin URL',
                      ),
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _saveUrl(),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _loading ? null : _saveUrl,
                          icon: _loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.save, size: 18),
                          label: const Text('Simpan'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _resetToDefault,
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Status card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Saat Ini',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'URL Aktif: ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        ApiConfig.activeUrl,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: OctaviaColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Default: ${ApiConfig.defaultBaseUrl}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Warning card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 18, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Text(
                      'Catatan Penting',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Pastikan HP dan server terhubung ke WiFi yang sama\n'
                  '• Setelah ganti URL, restart app untuk memastikan perubahan berlaku\n'
                  '• URL disimpan di SharedPreferences dan persisten',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFFEF4444).withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
