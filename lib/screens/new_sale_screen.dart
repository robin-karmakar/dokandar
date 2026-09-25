import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../services/firestore_service.dart';
import 'barcode_scanner_screen.dart';
import 'product_search_sheet.dart';
import 'receipt_screen.dart';

class NewSaleScreen extends StatefulWidget {
  const NewSaleScreen({super.key});

  @override
  State<NewSaleScreen> createState() => _NewSaleScreenState();
}

class _NewSaleScreenState extends State<NewSaleScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<CartItem> _cart = [];
  final _discountController = TextEditingController(text: '0');
  String _paymentMethod = 'Cash';
  bool _isSaving = false;

  double get _subtotal => _cart.fold(0, (sum, item) => sum + item.subtotal);

  double get _discount => double.tryParse(_discountController.text.trim()) ?? 0;

  double get _total {
    final t = _subtotal - _discount;
    return t < 0 ? 0 : t;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _addProductToCart(Product product) {
    if (product.stock <= 0) {
      _showMessage('${product.name} is out of stock');
      return;
    }

    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.productId == product.id);
      if (existingIndex != -1) {
        final existing = _cart[existingIndex];
        if (existing.quantity < product.stock) {
          existing.quantity += 1;
        } else {
          _showMessage('No more stock available for ${product.name}');
        }
      } else {
        _cart.add(CartItem(
          productId: product.id,
          name: product.name,
          price: product.price,
          availableStock: product.stock,
        ));
      }
    });
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode == null) return;

    final product = await _firestoreService.getProductByBarcode(barcode);

    if (!mounted) return;

    if (product == null) {
      _showMessage('Product not found for this barcode');
      return;
    }

    _addProductToCart(product);
  }

  Future<void> _searchProduct() async {
    final product = await showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ProductSearchSheet(),
    );

    if (product != null) {
      _addProductToCart(product);
    }
  }

  void _incrementQuantity(int index) {
    setState(() {
      final item = _cart[index];
      if (item.quantity < item.availableStock) {
        item.quantity += 1;
      } else {
        _showMessage('No more stock available for ${item.name}');
      }
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      final item = _cart[index];
      if (item.quantity > 1) {
        item.quantity -= 1;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  Future<void> _completeSale() async {
    if (_cart.isEmpty) {
      _showMessage('Cart is empty');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final invoiceNumber = await _firestoreService.recordInvoice(
        items: _cart,
        discount: _discount,
        paymentMethod: _paymentMethod,
      );

      final invoice = Invoice(
        id: '',
        invoiceNumber: invoiceNumber,
        items: _cart
            .map((item) => InvoiceItem(
          productId: item.productId,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
        ))
            .toList(),
        subtotal: _subtotal,
        discount: _discount,
        total: _total,
        paymentMethod: _paymentMethod,
        date: Timestamp.now(),
      );

      if (!mounted) return;

      setState(() {
        _cart.clear();
        _discountController.text = '0';
        _isSaving = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReceiptScreen(invoice: invoice)),
      );
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showMessage('Failed to complete sale. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Sale')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.search),
                    label: const Text('Search Product'),
                    onPressed: _searchProduct,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Barcode'),
                    onPressed: _scanBarcode,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _cart.isEmpty
                ? const Center(child: Text('Cart is empty. Scan or search to add products.'))
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _cart.length,
              itemBuilder: (context, index) {
                final item = _cart[index];
                return Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text('৳${item.price.toStringAsFixed(2)} × ${item.quantity}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _decrementQuantity(index),
                        ),
                        Text(item.quantity.toString()),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _incrementQuantity(index),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_cart.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('৳${_subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Discount'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(isDense: true, prefixText: '৳ '),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('৳${_total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('CASH'),
                          selected: _paymentMethod == 'Cash',
                          onSelected: (_) => setState(() => _paymentMethod = 'Cash'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('CARD'),
                          selected: _paymentMethod == 'Card',
                          onSelected: (_) => setState(() => _paymentMethod = 'Card'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                    onPressed: _completeSale,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('COMPLETE SALE'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}