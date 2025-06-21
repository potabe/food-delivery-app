// lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart'; // For @required
import 'package:food_app/models/food_item.dart';

class CartItem {
  final FoodItem foodItem;
  int quantity;

  CartItem({required this.foodItem, this.quantity = 1});

  // Method to update quantity (for internal use)
  void increaseQuantity() {
    quantity++;
  }

  void decreaseQuantity() {
    if (quantity > 1) {
      quantity--;
    }
  }
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items {
    return [..._items]; // Return a copy to prevent external modification
  }

  int get itemCount {
    return _items.fold(0, (total, current) => total + current.quantity);
  }

  double get totalAmount {
    return _items.fold(
      0.0,
      (total, current) => total + (current.foodItem.price * current.quantity),
    );
  }

  void addItem(FoodItem foodItem) {
    // Check if the item already exists in the cart
    int existingIndex = _items.indexWhere(
      (item) => item.foodItem.id == foodItem.id,
    );

    if (existingIndex >= 0) {
      // If exists, just increase quantity
      _items[existingIndex].increaseQuantity();
    } else {
      // If new, add a new CartItem
      _items.add(CartItem(foodItem: foodItem));
    }
    notifyListeners(); // Notify widgets that depend on this provider to rebuild
  }

  void removeItem(String foodItemId) {
    _items.removeWhere((item) => item.foodItem.id == foodItemId);
    notifyListeners();
  }

  void increaseQuantity(String foodItemId) {
    int existingIndex = _items.indexWhere(
      (item) => item.foodItem.id == foodItemId,
    );
    if (existingIndex >= 0) {
      _items[existingIndex].increaseQuantity();
      notifyListeners();
    }
  }

  void decreaseQuantity(String foodItemId) {
    int existingIndex = _items.indexWhere(
      (item) => item.foodItem.id == foodItemId,
    );
    if (existingIndex >= 0) {
      _items[existingIndex].decreaseQuantity();
      // If quantity becomes 0, remove the item
      if (_items[existingIndex].quantity == 0) {
        removeItem(foodItemId);
      } else {
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
