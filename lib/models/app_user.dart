// lib/models/app_user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid; // The Firebase Authentication User ID
  final String email;
  String name;
  String? phoneNumber; // Optional field
  String? address; // Optional field
  final Timestamp createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.address,
    required this.createdAt,
  });

  // Factory constructor to create an AppUser from a Firestore DocumentSnapshot
  factory AppUser.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data();
    return AppUser(
      uid: snapshot.id, // The document ID is the user's UID
      email: data?['email'] ?? '',
      name: data?['name'] ?? '',
      phoneNumber: data?['phoneNumber'],
      address: data?['address'],
      createdAt:
          data?['createdAt'] ?? Timestamp.now(), // Fallback to current time
    );
  }

  // Method to convert an AppUser object to a Firestore map (for saving/updating)
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'address': address,
      'createdAt': createdAt,
    };
  }

  // Method to convert AppUser object to a map for updating only specific fields
  Map<String, dynamic> toUpdateMap() {
    return {'name': name, 'phoneNumber': phoneNumber, 'address': address};
  }
}
