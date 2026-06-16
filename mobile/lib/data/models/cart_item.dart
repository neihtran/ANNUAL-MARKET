class CartItem {
  final String productId;
  final String shopId;
  final String shopName;
  final String productName;
  final String imageUrl;
  final double price;
  final int quantity;
  final String unit;
  final int stock;
  final String? marketId;
  final String? marketName;

  CartItem({
    required this.productId,
    required this.shopId,
    required this.shopName,
    required this.productName,
    required this.imageUrl,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.stock,
    this.marketId,
    this.marketName,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      productId: productId,
      shopId: shopId,
      shopName: shopName,
      productName: productName,
      imageUrl: imageUrl,
      price: price,
      quantity: quantity ?? this.quantity,
      unit: unit,
      stock: stock,
      marketId: marketId,
      marketName: marketName,
    );
  }

  double get total => price * quantity;

  Map<String, dynamic> toOrderItem() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}
