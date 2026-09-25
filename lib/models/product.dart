class Product {
  final String id;
  final String name;
  final double price;
  final int stock;
  final String barcode;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.barcode,
  });

  // Creates a Product object from Firestore data.
  factory Product.fromMap(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      stock: (data['stock'] ?? 0).toInt(),
      barcode: data['barcode'] ?? '',
    );
  }

  // Creates a Map from a Product object for saving to Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'stock': stock,
      'barcode': barcode,
    };
  }
}