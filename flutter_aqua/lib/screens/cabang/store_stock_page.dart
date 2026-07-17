import 'package:flutter/material.dart';
import '../../widgets/shared.dart';

class StoreStockPage extends StatelessWidget {
  final List<dynamic> stokTersedia;
  const StoreStockPage({super.key, required this.stokTersedia});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Stok Toko')),
      body: stokTersedia.isEmpty
          ? const Center(child: Text('Belum ada data stok'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: stokTersedia.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = stokTersedia[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: item['gambar_url'] != null &&
                          item['gambar_url'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            absolutizeUrl(item['gambar_url']),
                            width: 50, height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderIcon(cs),
                          ),
                        )
                      : _placeholderIcon(cs),
                  title: Text(item['nama_produk'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('SKU: ${item['sku']}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item['stok_tersedia']}',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: cs.tertiary)),
                      Text('${item['satuan']}',
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _placeholderIcon(ColorScheme cs) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_not_supported, color: cs.onSurfaceVariant),
    );
  }
}
