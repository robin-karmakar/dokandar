class CartItem {
  final String productId;
  final String name;
  final double price;
  final int availableStock;
  int quantity;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.availableStock,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;
}