import 'package:flutter/material.dart';
import '../../widgets/shared.dart';

class StoreStockPage extends StatelessWidget {
  final List<dynamic> stokTersedia;
  const StoreStockPage({super.key, required this.stokTersedia});

  @override
  Widget build(BuildContext context) {
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
                            errorBuilder: (_, __, ___) => _placeholderIcon(),
                          ),
                        )
                      : _placeholderIcon(),
                  title: Text(item['nama_produk'] ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('SKU: ${item['sku']}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item['stok_tersedia']}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      Text('${item['satuan']}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
