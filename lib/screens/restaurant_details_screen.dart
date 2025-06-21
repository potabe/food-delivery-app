// lib/screens/restaurant_details_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

import 'package:food_app/models/restaurant.dart';
import 'package:food_app/models/food_item.dart';
import 'package:food_app/models/review.dart';
import 'package:food_app/models/app_user.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/screens/cart_screen.dart';
import 'package:food_app/widgets/restaurant_reviews_list.dart'; // Import new reviews widget
import 'package:food_app/widgets/restaurant_menu_list.dart'; // Import new menu widget

class RestaurantDetailsScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailsScreen({super.key, required this.restaurant});

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  double _averageRating = 0.0;
  int _reviewCount = 0;

  // --- FIX FOR 'VOID' ERROR: Function now correctly returns Future<bool?> ---
  Future<bool?> _showReviewDialog(BuildContext context) async {
    // ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Make sure this is 'Future<bool?>'

    double _selectedRating = 3.0;
    final _commentController = TextEditingController();

    String userName = 'Anonymous';
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (userDoc.exists) {
        final appUser = AppUser.fromFirestore(userDoc, null);
        userName = appUser.name.isNotEmpty
            ? appUser.name
            : (currentUser.email?.split('@')[0] ?? 'Anonymous');
      } else {
        userName = currentUser.email?.split('@')[0] ?? 'Anonymous';
      }
    }

    // showDialog now correctly returns a boolean result
    bool? result = await showDialog<bool>(
      // Make sure '<bool>' is here
      context: context,
      builder: (ctx) {
        bool isSubmittingReview = false; // Local state for this dialog instance

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateInDialog) {
            return AlertDialog(
              title: const Text('Rate this Restaurant'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Your rating for ${widget.restaurant.name}'),
                    const SizedBox(height: 15),
                    RatingBar.builder(
                      initialRating: _selectedRating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      onRatingUpdate: (rating) {
                        setStateInDialog(() {
                          _selectedRating = rating;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        labelText: 'Your comments (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmittingReview
                      ? null
                      : () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                isSubmittingReview
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: CircularProgressIndicator(),
                      )
                    : ElevatedButton(
                        onPressed: () async {
                          if (currentUser == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please log in to submit a review.',
                                ),
                              ),
                            );
                            Navigator.of(ctx).pop(false);
                            return;
                          }

                          setStateInDialog(() {
                            isSubmittingReview = true;
                          });

                          try {
                            final newReview = Review(
                              reviewId: '',
                              restaurantId: widget.restaurant.id,
                              userId: currentUser.uid,
                              userName: userName,
                              rating: _selectedRating,
                              comment: _commentController.text.trim(),
                              timestamp: Timestamp.now(),
                            );

                            await _firestore
                                .collection('reviews')
                                .add(newReview.toFirestore());

                            Navigator.of(ctx).pop(true);
                          } catch (e) {
                            print('Error submitting review: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to submit review: $e'),
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                              ),
                            );
                            setStateInDialog(() {
                              isSubmittingReview = false;
                            });
                          }
                        },
                        child: const Text('SUBMIT REVIEW'),
                      ),
              ],
            );
          },
        );
      },
    );
    _commentController.dispose();

    // Verify this line is exactly as below:
    return result; // Correctly returns the bool? result
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurant.name),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CartScreen(),
                        ),
                      );
                    },
                  ),
                  if (cartProvider.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              widget.restaurant.imageUrl,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.restaurant.name,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        _averageRating > 0
                            ? _averageRating.toStringAsFixed(1)
                            : 'No reviews',
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (_reviewCount > 0)
                        Text(
                          ' ($_reviewCount reviews)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.delivery_dining,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.restaurant.deliveryTime,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // --- FIX FOR VARIABLE NAME AND VOID ERROR ---
                        bool? success = await _showReviewDialog(
                          context,
                        ); // Use 'success' variable
                        // --- END FIX ---
                        if (success == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Review submitted successfully!'),
                            ),
                          );
                        } else if (success == false) {
                          // Error handled within dialog, or user cancelled
                        }
                      },
                      icon: const Icon(Icons.rate_review),
                      label: const Text('WRITE A REVIEW'),
                    ),
                  ),
                ],
              ),
            ),

            RestaurantReviewsList(
              restaurantId: widget.restaurant.id,
              onRatingCalculated: (averageRating, reviewCount) {
                print(
                  'RestaurantDetails: Callback received - Avg: $averageRating, Count: $reviewCount',
                );
                if (_averageRating != averageRating ||
                    _reviewCount != reviewCount) {
                  if (mounted) {
                    setState(() {
                      _averageRating = averageRating;
                      _reviewCount = reviewCount;
                    });
                    print('RestaurantDetails: setState called.');
                  }
                } else {
                  print(
                    'RestaurantDetails: setState skipped (values unchanged).',
                  );
                }
              },
            ),

            const SizedBox(height: 16),
            RestaurantMenuList(restaurantId: widget.restaurant.id),
          ],
        ),
      ),
    );
  }
}
