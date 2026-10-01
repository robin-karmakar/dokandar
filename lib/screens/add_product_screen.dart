import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';
import 'barcode_scanner_screen.dart';

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

  Future<void> _scanBarcode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (scannedCode != null) {
      setState(() {
        _barcodeController.text = scannedCode;
      });
    }
  }

  Future<void> _handleAddProduct() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final stockText = _stockController.text.trim();
    final barcode = _barcodeController.text.trim();

    // Barcode is now optional — only name, price, and stock are required.
    if (name.isEmpty || priceText.isEmpty || stockText.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in name, price, and stock";
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
      barcode: barcode, // stays empty string if left blank
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
                decoration: InputDecoration(
                  labelText: 'Barcode (optional)',
                  prefixIcon: const Icon(Icons.qr_code),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: 'Scan barcode',
                    onPressed: _scanBarcode,
                  ),
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