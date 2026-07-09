import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';

// ==================== FORMAT HELPERS ====================

String absolutizeUrl(String? u) {
  if (u == null) return '';
  var s = u.trim();
  if (s.isEmpty) return '';
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  if (!s.startsWith('/')) s = '/$s';
  return '${ApiConfig.baseUrl}$s';
}

int toInt(dynamic v, {int def = 0}) {
  if (v == null) return def;
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v.toString()) ?? def;
}

String formatCurrency(num? value) {
  if (value == null) return 'Rp 0';
  final s = value.toInt().toString();
  var res = '';
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && i % 3 == 0) res = '.$res';
    res = '${s[s.length - 1 - i]}$res';
  }
  return 'Rp $res';
}

// ==================== WIDGETS ====================

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    IconData icon = Icons.hourglass_bottom;
    String text = status;

    if (s.contains('diterima') || s == 'selesai') {
      icon = Icons.check_circle;
      text = 'Diterima';
    } else if (s.contains('ditolak') || s == 'rejected') {
      icon = Icons.cancel;
      text = 'Ditolak';
    } else if (s.contains('draft')) {
      icon = Icons.edit_note;
      text = 'Draft';
    } else if (s == 'dikirim' || s.contains('kirim')) {
      icon = Icons.local_shipping;
      text = 'Dikirim';
    } else if (s == 'dipaket') {
      icon = Icons.inventory_2;
      text = 'Dikemas';
    } else if (s == 'approved_sales') {
      icon = Icons.thumb_up;
      text = 'Disetujui Sales';
    } else if (s == 'approved_admin') {
      icon = Icons.verified;
      text = 'Diverifikasi';
    } else if (s == 'pending') {
      icon = Icons.hourglass_empty;
      text = 'Pending';
    }

    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(text, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(color: Colors.black54))),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w800))),
      ],
    );
  }
}

class ProductThumb extends StatelessWidget {
  final String url;
  const ProductThumb({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (url.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: cs.surfaceContainerHighest,
        ),
        child: Icon(Icons.inventory_2, color: cs.onSurfaceVariant),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        absolutizeUrl(url),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        loadingBuilder: (c, w, p) =>
            p == null ? w : Container(color: Colors.black12, width: 56, height: 56),
        errorBuilder: (_, __, ___) => Container(
          width: 56,
          height: 56,
          color: cs.surfaceContainerHighest,
          child: Icon(Icons.broken_image, color: cs.onSurfaceVariant),
        ),
      ),
    );
  }
}

class ServerProofs extends StatelessWidget {
  final List<String> urls;
  const ServerProofs({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return const Card(
          child: Padding(
              padding: EdgeInsets.all(14),
              child: Text('Belum ada bukti di server')));
    }
    final fixed =
        urls.map((u) => absolutizeUrl(u)).where((u) => u.isNotEmpty).toList();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: fixed.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (_, i) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          fixed[i],
          fit: BoxFit.cover,
          loadingBuilder: (c, w, p) =>
              p == null ? w : Container(color: Colors.black12),
          errorBuilder: (_, __, ___) => Container(
              color: Colors.black12, child: const Icon(Icons.broken_image)),
        ),
      ),
    );
  }
}

class LocalProofs extends StatelessWidget {
  final List<XFile> photos;
  final void Function(int index)? onRemove;
  const LocalProofs({super.key, required this.photos, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Card(
          child: Padding(
              padding: EdgeInsets.all(14), child: Text('Belum ada foto')));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (_, i) {
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(File(photos[i].path), fit: BoxFit.cover),
              ),
            ),
            if (onRemove != null)
              Positioned(
                right: 6,
                top: 6,
                child: InkWell(
                  onTap: () => onRemove!(i),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
