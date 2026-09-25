import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();

  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleAddProduct() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final stockText = _stockController.text.trim();
    final barcode = _barcodeController.text.trim();

    if (name.isEmpty || priceText.isEmpty || stockText.isEmpty || barcode.isEmpty) {
      setState(() {
        _errorMessage = "Please fill all fields";
      });
      return;
    }

    final price = double.tryParse(priceText);
    final stock = int.tryParse(stockText);

    if (price == null || stock == null) {
      setState(() {
        _errorMessage = "Price and stock must be valid numbers";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final product = Product(
      id: '',
      name: name,
      price: price,
      stock: stock,
      barcode: barcode,
    );

    await _firestoreService.addProduct(product);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  labelText: 'Barcode',
                  prefixIcon: Icon(Icons.qr_code),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _handleAddProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text('Save Product'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}