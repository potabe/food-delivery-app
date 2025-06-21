// lib/models/review.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String reviewId; // Firestore document ID
  final String restaurantId;
  final String userId;
  final String userName; // Denormalized for easy display
  final double rating; // 1.0 to 5.0
  final String comment;
  final Timestamp timestamp;

  Review({
    required this.reviewId,
    required this.restaurantId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.timestamp,
  });

  // Factory constructor to create a Review from a Firestore DocumentSnapshot
  factory Review.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw Exception("Review data is null");
    }
    return Review(
      reviewId: snapshot.id, // Document ID is the review ID
      restaurantId: data['restaurantId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      rating: (data['rating'] as num).toDouble(),
      comment: data['comment'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  // Method to convert a Review object to a Firestore Map for saving
  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'timestamp': timestamp,
    };
  }
}
