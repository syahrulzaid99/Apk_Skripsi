import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/shared.dart' show isConnectionError, showChangeServerDialog;
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

  /// Tampilkan dialog ubah IP server, lalu ulangi fetch profil jika URL berubah.
  Future<void> _changeServerAndRetry() async {
    final changed = await showChangeServerDialog(context);
    if (changed && mounted) _fetchProfile();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final cs = Theme.of(context).colorScheme;
    if (_user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _connectionFailed ? Icons.cloud_off : Icons.error_outline,
                size: 48,
                color: cs.error,
              ),
              const SizedBox(height: 12),
              Text(
                _connectionFailed
                    ? 'Gagal terhubung ke server'
                    : 'Gagal memuat profil',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                _connectionFailed
                    ? 'Periksa IP server backend Anda.'
                    : 'Terjadi kesalahan saat memuat profil.',
                style: TextStyle(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
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
    return ListView(padding: const EdgeInsets.all(16), children: [
      CircleAvatar(
          radius: 40,
          backgroundColor: cs.primaryContainer,
          child: Icon(Icons.person, size: 40, color: cs.onPrimaryContainer)),
      const SizedBox(height: 16),
      Text(u['username'] ?? '-',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      Text((u['role'] ?? '-').toString().toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
      const SizedBox(height: 24),
      Card(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildItem(cs, 'Nama Cabang', u['nama_cabang']),
                    const Divider(),
                    _buildItem(cs, 'Provinsi', u['provinsi']),
                    const Divider(),
                    _buildItem(cs, 'Kota', u['kota']),
                    const Divider(),
                    _buildItem(cs, 'Jalan', u['jalan']),
                  ]))),
      const SizedBox(height: 16),
      FilledButton.icon(
          onPressed: () async {
            final changed = await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EditProfilePage(user: u)));
            if (changed == true) _fetchProfile();
          },
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profil')),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
        },
        icon: const Icon(Icons.settings),
        label: const Text('Pengaturan'),
      ),
    ]);
  }

  Widget _buildItem(ColorScheme cs, String label, dynamic value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Text(
              value?.toString().isNotEmpty == true ? value.toString() : '-',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ]));
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
        'password': _passCtrl.text
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
    return Scaffold(
        appBar: AppBar(title: const Text('Edit Profil')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: _namaCtrl,
              decoration: const InputDecoration(labelText: 'Nama Cabang')),
          const SizedBox(height: 12),
          TextField(
              controller: _provCtrl,
              decoration: const InputDecoration(labelText: 'Provinsi')),
          const SizedBox(height: 12),
          TextField(
              controller: _kotaCtrl,
              decoration: const InputDecoration(labelText: 'Kota')),
          const SizedBox(height: 12),
          TextField(
              controller: _jalanCtrl,
              decoration: const InputDecoration(labelText: 'Jalan')),
          const SizedBox(height: 12),
          TextField(
              controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                  labelText: 'Password Baru (Opsional)',
                  suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure)))),
          const SizedBox(height: 24),
          FilledButton.icon(
              onPressed: _loading ? null : _save,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('Simpan Perubahan')),
        ]));
  }
}
