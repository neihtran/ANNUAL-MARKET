import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/cart_item.dart';

class CartState {
  final List<CartItem> items;
  final String? marketId;
  final String? marketName;

  const CartState({
    this.items = const [],
    this.marketId,
    this.marketName,
  });

  CartState copyWith({
    List<CartItem>? items,
    String? marketId,
    String? marketName,
  }) {
    return CartState(
      items: items ?? this.items,
      marketId: marketId ?? this.marketId,
      marketName: marketName ?? this.marketName,
    );
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => items.isEmpty;
}

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState());

  void addItem({
    required String productId,
    required String shopId,
    required String shopName,
    required String productName,
    required String imageUrl,
    required double price,
    required int quantity,
    required String unit,
    required int stock,
    required String marketId,
    required String marketName,
  }) {
    // Nếu cart có sản phẩm từ chợ khác → reset cart
    if (state.marketId != null && state.marketId != marketId) {
      emit(CartState(
        items: [
          CartItem(
            productId: productId,
            shopId: shopId,
            shopName: shopName,
            productName: productName,
            imageUrl: imageUrl,
            price: price,
            quantity: quantity,
            unit: unit,
            stock: stock,
            marketId: marketId,
            marketName: marketName,
          )
        ],
        marketId: marketId,
        marketName: marketName,
      ));
      return;
    }

    final existingIndex = state.items.indexWhere((i) => i.productId == productId);
    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(state.items);
      final existing = updated[existingIndex];
      final newQty = existing.quantity + quantity;
      updated[existingIndex] = existing.copyWith(quantity: newQty > stock ? stock : newQty);
      emit(state.copyWith(items: updated, marketId: marketId, marketName: marketName));
    } else {
      final newItem = CartItem(
        productId: productId,
        shopId: shopId,
        shopName: shopName,
        productName: productName,
        imageUrl: imageUrl,
        price: price,
        quantity: quantity > stock ? stock : quantity,
        unit: unit,
        stock: stock,
        marketId: marketId,
        marketName: marketName,
      );
      emit(state.copyWith(
        items: [...state.items, newItem],
        marketId: marketId,
        marketName: marketName,
      ));
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final updated = state.items.map((item) {
      if (item.productId == productId) {
        return item.copyWith(quantity: quantity > item.stock ? item.stock : quantity);
      }
      return item;
    }).toList();
    emit(state.copyWith(items: updated));
  }

  void removeItem(String productId) {
    final updated = state.items.where((i) => i.productId != productId).toList();
    emit(CartState(
      items: updated,
      marketId: updated.isEmpty ? null : state.marketId,
      marketName: updated.isEmpty ? null : state.marketName,
    ));
  }

  void clearCart() {
    emit(const CartState());
  }
}
