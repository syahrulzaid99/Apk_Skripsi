import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../widgets/smooth_list_item.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _fetch(); }

  void _snack(String msg) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.getAdminUsers();
      if (res.statusCode == 200) {
        _users = (jsonDecode(res.body)['users'] as List? ?? []).cast<Map<String, dynamic>>();
      }
    } catch (_) { _snack('Gagal memuat'); }
    finally { if (mounted) setState(() => _loading = false); }
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin': return Colors.red;
      case 'cabang': return Colors.blue;
      case 'sales': return Colors.green;
      case 'gudang': return Colors.orange;
      default: return Colors.grey;
    }
  }

  void _showForm({Map<String, dynamic>? user}) {
    final isEdit = user != null;
    final uCtrl = TextEditingController(text: user?['username'] ?? '');
    final pCtrl = TextEditingController();
    final namaCtrl = TextEditingController(text: user?['nama_cabang'] ?? '');
    final provCtrl = TextEditingController(text: user?['provinsi'] ?? '');
    final kotaCtrl = TextEditingController(text: user?['kota'] ?? '');
    final jalanCtrl = TextEditingController(text: user?['jalan'] ?? '');
    String role = user?['role'] ?? 'cabang';
    var obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(isEdit ? 'Edit User' : 'Tambah User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: uCtrl, decoration: const InputDecoration(labelText: 'Username', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: pCtrl, obscureText: obscure, decoration: InputDecoration(
              labelText: isEdit ? 'Password Baru (kosongkan jika tidak diubah)' : 'Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility : Icons.visibility_off), onPressed: () => setSt(() => obscure = !obscure)),
            )),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: role,
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Admin')),
                DropdownMenuItem(value: 'cabang', child: Text('Cabang')),
                DropdownMenuItem(value: 'sales', child: Text('Sales')),
                DropdownMenuItem(value: 'gudang', child: Text('Gudang')),
              ],
              onChanged: (v) => setSt(() => role = v ?? 'cabang'),
            ),
            if (role == 'cabang') ...[
              const SizedBox(height: 12),
              TextField(controller: namaCtrl, decoration: const InputDecoration(labelText: 'Nama Cabang', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: provCtrl, decoration: const InputDecoration(labelText: 'Provinsi', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: kotaCtrl, decoration: const InputDecoration(labelText: 'Kota', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: jalanCtrl, decoration: const InputDecoration(labelText: 'Jalan', border: OutlineInputBorder())),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                final data = <String, dynamic>{
                  'username': uCtrl.text.trim(),
                  'role': role,
                  'nama_cabang': namaCtrl.text.trim(),
                  'provinsi': provCtrl.text.trim(),
                  'kota': kotaCtrl.text.trim(),
                  'jalan': jalanCtrl.text.trim(),
                };
                if (pCtrl.text.isNotEmpty) data['password'] = pCtrl.text;

                if (data['username'].isEmpty) { _snack('Username wajib diisi'); return; }
                if (!isEdit && pCtrl.text.isEmpty) { _snack('Password wajib diisi'); return; }

                try {
                  final res = isEdit
                      ? await ApiClient.adminUpdateUser(user!['id'], data)
                      : await ApiClient.adminCreateUser(data);
                  if (res.statusCode == 200) {
                    Navigator.pop(ctx);
                    _snack(isEdit ? '✅ User diperbarui' : '✅ User dibuat');
                    _fetch();
                  } else {
                    final body = jsonDecode(res.body);
                    _snack(body['message'] ?? 'Gagal (${res.statusCode})');
                  }
                } catch (e) { _snack('Error: $e'); }
              },
              icon: const Icon(Icons.save),
              label: Text(isEdit ? 'Simpan' : 'Buat User'),
            ),
          ])),
        ),
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> u) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text('Yakin hapus user "${u['username']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final res = await ApiClient.adminDeleteUser(u['id']);
      if (res.statusCode == 200) { _snack('🗑️ User dihapus'); _fetch(); }
      else _snack('Gagal menghapus');
    } catch (e) { _snack('Error: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (_loading && _users.isEmpty) return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: ShimmerBox(width: double.infinity, height: 60, borderRadius: BorderRadius.circular(12)),
      ),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _users.isEmpty
            ? ListView(children: const [SizedBox(height: 80), Center(child: Text('Tidak ada user'))])
            : ListView.builder(padding: const EdgeInsets.all(16), itemCount: _users.length, itemBuilder: (_, i) {
                final u = _users[i];
                final role = (u['role'] ?? '').toString();
                return Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
                  leading: CircleAvatar(backgroundColor: _roleColor(role), child: Text(role[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  title: Text(u['username'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(role.toUpperCase(), style: TextStyle(fontSize: 11, color: _roleColor(role), fontWeight: FontWeight.w600)),
                    if (u['nama_cabang']?.toString().isNotEmpty == true)
                      Text(u['nama_cabang'], style: TextStyle(fontSize: 12, color: cs.outline)),
                  ]),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(onPressed: () => _showForm(user: u), icon: const Icon(Icons.edit_outlined), tooltip: 'Edit'),
                    IconButton(onPressed: () => _delete(u), icon: Icon(Icons.delete_outline, color: cs.error), tooltip: 'Hapus'),
                  ]),
                ));
              }),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
