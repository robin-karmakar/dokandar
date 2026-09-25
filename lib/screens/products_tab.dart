import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';

class ProductsTab extends StatelessWidget {
  ProductsTab({super.key});

  final FirestoreService _firestoreService = FirestoreService();
  final int lowStockThreshold = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        elevation: 0,
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Product',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _firestoreService.getProducts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No products yet. Add one!'));
          }

          final products = snapshot.data!;
          final lowStockProducts =
              products.where((p) => p.stock <= lowStockThreshold).toList();

          return Column(
            children: [
              if (lowStockProducts.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Colors.orange.shade100,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${lowStockProducts.length} product(s) running low on stock',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final isLowStock = product.stock <= lowStockThreshold;

                    return Dismissible(
                      key: Key(product.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Product'),
                            content: Text('Delete "${product.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) {
                        _firestoreService.deleteProduct(product.id);
                      },
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLowStock
                              ? Colors.red.withOpacity(0.15)
                              : Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          child: Icon(
                            Icons.inventory_2_outlined,
                            color: isLowStock ? Colors.red : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Barcode: ${product.barcode}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EditProductScreen(product: product),
                            ),
                          );
                        },
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('৳${product.price.toStringAsFixed(2)}'),
                            Text(
                              'Stock: ${product.stock}',
                              style: TextStyle(
                                color: isLowStock ? Colors.red : Colors.black87,
                                fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}