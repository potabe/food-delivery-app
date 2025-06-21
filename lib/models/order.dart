// lib/models/order.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_app/models/order_item.dart';

class Order {
  final String orderId; // Unique ID from Firestore document ID
  final String userId;
  final String restaurantName; // Name of the restaurant for easy display
  final List<OrderItem> items;
  final double totalAmount;
  final Timestamp orderDate;
  final String status; // e.g., 'Pending', 'Preparing', 'Delivered'

  Order({
    required this.orderId,
    required this.userId,
    required this.restaurantName,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    this.status = 'Delivered', // Default status for now
  });

  // Factory constructor to create an Order from a Firestore DocumentSnapshot
  factory Order.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("Order data is null"); // Or handle gracefully
    }
    return Order(
      orderId: snapshot.id,
      userId: data['userId'] ?? '',
      restaurantName: data['restaurantName'] ?? 'Unknown Restaurant',
      items: (data['items'] as List)
          .map((itemMap) => OrderItem.fromMap(itemMap as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      orderDate: data['orderDate'] as Timestamp,
      status: data['status'] ?? 'Delivered',
    );
  }

  // Method to convert an Order object to a Firestore Map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'restaurantName': restaurantName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'orderDate': orderDate,
      'status': status,
    };
  }
}
