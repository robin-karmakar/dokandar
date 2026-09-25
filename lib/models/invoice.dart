import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;

  InvoiceItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  factory InvoiceItem.fromMap(Map<String, dynamic> data) {
    return InvoiceItem(
      productId: data['productId'] ?? '',
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: (data['quantity'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
}

class Invoice {
  final String id;
  final int invoiceNumber;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final String paymentMethod;
  final Timestamp date;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.paymentMethod,
    required this.date,
  });

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory Invoice.fromMap(String id, Map<String, dynamic> data) {
    return Invoice(
      id: id,
      invoiceNumber: (data['invoiceNumber'] ?? 0).toInt(),
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => InvoiceItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (data['subtotal'] ?? 0).toDouble(),
      discount: (data['discount'] ?? 0).toDouble(),
      total: (data['total'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      date: data['date'] ?? Timestamp.now(),
    );
  }
}