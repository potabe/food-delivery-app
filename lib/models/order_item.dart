// lib/models/order_item.dart
// import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String foodItemId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  OrderItem({
    required this.foodItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  // Factory constructor to create OrderItem from a Firestore Map
  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      foodItemId: data['foodItemId'] as String,
      name: data['name'] as String,
      price: (data['price'] as num).toDouble(), // Cast to num then to double
      quantity: data['quantity'] as int,
      imageUrl: data['imageUrl'] as String,
    );
  }

  // Method to convert OrderItem to a Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'foodItemId': foodItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }
}
