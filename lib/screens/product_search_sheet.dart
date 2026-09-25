import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';

class ProductSearchSheet extends StatefulWidget {
  const ProductSearchSheet({super.key});

  @override
  State<ProductSearchSheet> createState() => _ProductSearchSheetState();
}

class _ProductSearchSheetState extends State<ProductSearchSheet> {
  final FirestoreService _firestoreService = FirestoreService();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Select Product',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Search product',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<List<Product>>(
                  stream: _firestoreService.getProducts(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final products = snapshot.data!
                        .where((p) => p.name.toLowerCase().contains(_query))
                        .toList();

                    if (products.isEmpty) {
                      return const Center(child: Text('No products found'));
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text('Stock: ${product.stock}'),
                          trailing: Text('৳${product.price.toStringAsFixed(2)}'),
                          enabled: product.stock > 0,
                          onTap: product.stock > 0
                              ? () => Navigator.pop(context, product)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}