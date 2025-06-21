// lib/models/food_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
  });

  // Factory constructor to create a FoodItem from a Firestore DocumentSnapshot
  factory FoodItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return FoodItem(
      id: snapshot.id,
      name: data?['name'] ?? 'No Name',
      description: data?['description'] ?? 'No description available.',
      price: (data?['price'] ?? 0.0).toDouble(),
      imageUrl:
          data?['imageUrl'] ??
          'https://via.placeholder.com/150', // Placeholder image
    );
  }

  // Method to convert a FoodItem object to a Firestore map (if needed for saving/updating)
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
    };
  }
}
