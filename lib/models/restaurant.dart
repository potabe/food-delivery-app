// lib/models/restaurant.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String id; // Unique ID from Firestore
  final String name;
  final String imageUrl;
  final double rating;
  final String deliveryTime;

  Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.deliveryTime,
  });

  // Factory constructor to create a Restaurant from a Firestore DocumentSnapshot
  factory Restaurant.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data(); // Get the data map from the snapshot
    return Restaurant(
      id: snapshot.id, // The document ID itself
      name: data?['name'] ?? '', // Access fields by their keys
      imageUrl: data?['imageUrl'] ?? '',
      rating: (data?['rating'] ?? 0.0).toDouble(), // Ensure it's a double
      deliveryTime: data?['deliveryTime'] ?? '',
    );
  }

  // Method to convert a Restaurant object to a Firestore map (useful for adding/updating)
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'rating': rating,
      'deliveryTime': deliveryTime,
    };
  }
}
