import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../config/theme.dart';

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

// ==================== OCTAVIA WIDGETS ====================

/// Section heading with icon — Octavia style
class SectionHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;

  const SectionHeading({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: OctaviaColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: OctaviaColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Stat card — Octavia dashboard style
class OctaviaStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const OctaviaStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Status chip — Octavia pill style
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    IconData icon = Icons.hourglass_bottom;
    String text = status;
    Color color = OctaviaColors.textMuted;

    if (s.contains('diterima') || s == 'selesai') {
      icon = Icons.check_circle;
      text = 'Diterima';
      color = OctaviaColors.accentGreen;
    } else if (s.contains('ditolak') || s == 'rejected') {
      icon = Icons.cancel;
      text = 'Ditolak';
      color = const Color(0xFFEF4444);
    } else if (s.contains('draft')) {
      icon = Icons.edit_note;
      text = 'Draft';
      color = OctaviaColors.textMuted;
    } else if (s == 'dikirim' || s.contains('kirim')) {
      icon = Icons.local_shipping;
      text = 'Dikirim';
      color = OctaviaColors.primary;
    } else if (s == 'dipaket') {
      icon = Icons.inventory_2;
      text = 'Dikemas';
      color = const Color(0xFFF59E0B);
    } else if (s == 'approved_sales') {
      icon = Icons.thumb_up;
      text = 'Disetujui Sales';
      color = OctaviaColors.primary;
    } else if (s == 'approved_admin') {
      icon = Icons.verified;
      text = 'Diverifikasi';
      color = OctaviaColors.badgePro;
    } else if (s == 'pending') {
      icon = Icons.hourglass_empty;
      text = 'Pending';
      color = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Info row — label: value layout
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: OctaviaColors.primary),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

/// Product thumbnail
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
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          color: cs.surfaceContainerHighest,
        ),
        child: Icon(Icons.inventory_2, color: cs.onSurfaceVariant),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
      child: Image.network(
        absolutizeUrl(url),
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        loadingBuilder: (c, w, p) => p == null
            ? w
            : Container(
                color: cs.surfaceContainerHighest,
                width: 56,
                height: 56,
              ),
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

/// Server proofs grid
class ServerProofs extends StatelessWidget {
  final List<String> urls;
  const ServerProofs({super.key, required this.urls});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (urls.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Row(
          children: [
            Icon(Icons.image_outlined, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 10),
            Text(
              'Belum ada bukti di server',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
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
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        child: Image.network(
          fixed[i],
          fit: BoxFit.cover,
          loadingBuilder: (c, w, p) =>
              p == null ? w : Container(color: cs.surfaceContainerHighest),
          errorBuilder: (_, __, ___) => Container(
            color: cs.surfaceContainerHighest,
            child: Icon(Icons.broken_image, color: cs.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// Local proofs grid
class LocalProofs extends StatelessWidget {
  final List<XFile> photos;
  final void Function(int index)? onRemove;
  const LocalProofs({super.key, required this.photos, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Row(
          children: [
            Icon(Icons.camera_alt_outlined, color: cs.onSurfaceVariant, size: 20),
            const SizedBox(width: 10),
            Text(
              'Belum ada foto',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
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
                borderRadius: BorderRadius.circular(AppTheme.radiusButton),
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
                    child:
                        const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Octavia-styled card with shadow
class OctaviaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final VoidCallback? onTap;

  const OctaviaCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Mini list item card — Octavia style
class OctaviaMiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;
  final String? amount;

  const OctaviaMiniCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: trailingColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  trailing,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: trailingColor,
                  ),
                ),
              ),
              if (amount != null) ...[
                const SizedBox(height: 3),
                Text(
                  amount!,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== CONNECTION HELPERS ====================

/// True jika error berasal dari kegagalan koneksi ke server
bool isConnectionError(Object e) {
  if (e is SocketException) return true;
  if (e is TimeoutException) return true;
  if (e is HttpException) return true;
  if (e is HandshakeException) return true;
  final msg = e.toString().toLowerCase();
  return msg.contains('socket') ||
      msg.contains('timeout') ||
      msg.contains('connection') ||
      msg.contains('failed to connect') ||
      msg.contains('no address associated') ||
      msg.contains('network is unreachable') ||
      msg.contains('connection refused');
}

/// Tampilkan dialog untuk mengubah IP/URL server backend secara langsung.
Future<bool> showChangeServerDialog(BuildContext context) async {
  final ctrl = TextEditingController(text: ApiConfig.activeUrl);
  final focusNode = FocusNode();
  var loading = false;
  var error = '';

  Future<void> doSave(StateSetter setSt) async {
    focusNode.unfocus();
    await Future.delayed(const Duration(milliseconds: 200));

    final ok = await _commitServerUrl(
      ctrl.text.trim(),
      (m) => setSt(() => error = m),
      (v) => setSt(() => loading = v),
    );
    if (ok) {
      Navigator.of(context, rootNavigator: true).pop(true);
    }
  }

  final result = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setSt) => AlertDialog(
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: OctaviaColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.dns, size: 16, color: OctaviaColors.primary),
          ),
          const SizedBox(width: 10),
          const Text('Ubah IP Server'),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Masukkan IP/URL server backend yang benar lalu simpan.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: 'Server URL',
                  hintText: 'http://192.168.x.x:3000',
                  prefixIcon: const Icon(Icons.link),
                  errorText: error.isNotEmpty ? error : null,
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => doSave(setSt),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: loading ? null : () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: loading ? null : () => doSave(setSt),
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: const Text('Simpan'),
          ),
        ],
      ),
    ),
  );

  ctrl.dispose();
  focusNode.dispose();
  return result == true;
}

/// Validasi & simpan URL server.
Future<bool> _commitServerUrl(
  String url,
  void Function(String) setError,
  void Function(bool) setLoading,
) async {
  if (url.isEmpty) {
    setError('URL tidak boleh kosong');
    return false;
  }
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    setError('URL harus dimulai dengan http:// atau https://');
    return false;
  }
  setError('');
  setLoading(true);
  try {
    await ApiConfig.setBaseUrl(url);
    return true;
  } catch (e) {
    setError('Error: $e');
    return false;
  } finally {
    setLoading(false);
  }
}
