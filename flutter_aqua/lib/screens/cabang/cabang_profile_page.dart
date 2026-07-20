import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart' show isConnectionError, showChangeServerDialog, OctaviaCard, SectionHeading;
import '../settings/settings_page.dart';

class CabangProfilePage extends StatefulWidget {
  const CabangProfilePage({super.key});

  @override
  State<CabangProfilePage> createState() => _CabangProfilePageState();
}

class _CabangProfilePageState extends State<CabangProfilePage> {
  Map<String, dynamic>? _user;
  bool _loading = false;
  bool _connectionFailed = false;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getMe();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        setState(() {
          _user = data['user'] as Map<String, dynamic>?;
          _connectionFailed = false;
        });
      }
    } catch (e) {
      setState(() {
        _connectionFailed = isConnectionError(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeServerAndRetry() async {
    final changed = await showChangeServerDialog(context);
    if (changed && mounted) _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _user == null) {
      return Center(
        child: CircularProgressIndicator(color: OctaviaColors.primary),
      );
    }
    final cs = Theme.of(context).colorScheme;
    if (_user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _connectionFailed ? Icons.cloud_off : Icons.error_outline,
                  size: 32,
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _connectionFailed
                    ? 'Gagal terhubung ke server'
                    : 'Gagal memuat profil',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _connectionFailed
                    ? 'Periksa IP server backend Anda.'
                    : 'Terjadi kesalahan saat memuat profil.',
                style: GoogleFonts.inter(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_connectionFailed)
                FilledButton.icon(
                  onPressed: _changeServerAndRetry,
                  icon: const Icon(Icons.dns),
                  label: const Text('Ubah IP Server'),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _fetchProfile,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final u = _user!;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Profile header ──
        Center(
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OctaviaColors.primary.withValues(alpha: 0.12),
                  border: Border.all(
                    color: OctaviaColors.primary.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Icon(Icons.person, size: 40, color: OctaviaColors.primary),
              ),
              const SizedBox(height: 14),
              Text(
                u['username'] ?? '-',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: OctaviaColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  (u['role'] ?? '-').toString().toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: OctaviaColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Info card ──
        OctaviaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(icon: Icons.info_outline, title: 'Informasi Cabang'),
              const SizedBox(height: 14),
              _buildItem(cs, 'Nama Cabang', u['nama_cabang']),
              Divider(color: cs.outlineVariant, height: 1),
              _buildItem(cs, 'Provinsi', u['provinsi']),
              Divider(color: cs.outlineVariant, height: 1),
              _buildItem(cs, 'Kota', u['kota']),
              Divider(color: cs.outlineVariant, height: 1),
              _buildItem(cs, 'Jalan', u['jalan']),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Action buttons ──
        FilledButton.icon(
          onPressed: () async {
            final changed = await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => EditProfilePage(user: u)),
            );
            if (changed == true) _fetchProfile();
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit Profil'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            );
          },
          icon: const Icon(Icons.settings, size: 18),
          label: const Text('Pengaturan'),
        ),
      ],
    );
  }

  Widget _buildItem(ColorScheme cs, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value?.toString().isNotEmpty == true ? value.toString() : '-',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _namaCtrl, _provCtrl, _kotaCtrl, _jalanCtrl;
  final _passCtrl = TextEditingController();
  bool _loading = false, _obscure = true;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _namaCtrl = TextEditingController(text: u['nama_cabang'] ?? '');
    _provCtrl = TextEditingController(text: u['provinsi'] ?? '');
    _kotaCtrl = TextEditingController(text: u['kota'] ?? '');
    _jalanCtrl = TextEditingController(text: u['jalan'] ?? '');
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _provCtrl.dispose();
    _kotaCtrl.dispose();
    _jalanCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      final data = {
        'nama_cabang': _namaCtrl.text.trim(),
        'provinsi': _provCtrl.text.trim(),
        'kota': _kotaCtrl.text.trim(),
        'jalan': _jalanCtrl.text.trim(),
        'password': _passCtrl.text,
      };
      final res = await ApiClient.updateProfile(data);
      if (res.statusCode == 200) {
        _snack('Profil berhasil diperbarui');
        if (mounted) Navigator.pop(context, true);
      } else {
        _snack('Gagal memperbarui profil');
      }
    } catch (e) {
      _snack('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Nama Cabang',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          TextField(controller: _namaCtrl),
          const SizedBox(height: 16),
          Text(
            'Provinsi',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          TextField(controller: _provCtrl),
          const SizedBox(height: 16),
          Text(
            'Kota',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          TextField(controller: _kotaCtrl),
          const SizedBox(height: 16),
          Text(
            'Jalan',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          TextField(controller: _jalanCtrl),
          const SizedBox(height: 16),
          Text(
            'Password Baru (Opsional)',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Simpan Perubahan'),
          ),
        ],
      ),
    );
  }
}
