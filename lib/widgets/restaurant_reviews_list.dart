// lib/widgets/restaurant_reviews_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

import 'package:food_app/models/review.dart';

class RestaurantReviewsList extends StatefulWidget {
  final String restaurantId;
  final Function(double averageRating, int reviewCount) onRatingCalculated;

  const RestaurantReviewsList({
    super.key,
    required this.restaurantId,
    required this.onRatingCalculated,
  });

  @override
  State<RestaurantReviewsList> createState() => _RestaurantReviewsListState();
}

class _RestaurantReviewsListState extends State<RestaurantReviewsList> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text('Customer Reviews', style: theme.textTheme.titleLarge),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('reviews')
              .where('restaurantId', isEqualTo: widget.restaurantId)
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              double calculatedAverageRating = 0.0;
              int calculatedReviewCount = 0;
              // Call the callback even if empty, to reset parent rating
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onRatingCalculated(
                  calculatedAverageRating,
                  calculatedReviewCount,
                );
              });

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.rate_review_outlined,
                        size: 60,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reviews yet for this restaurant.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to leave a review!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final reviews = snapshot.data!.docs.map((doc) {
              return Review.fromFirestore(doc, null);
            }).toList();

            double calculatedAverageRating = reviews.isNotEmpty
                ? reviews
                          .map((review) => review.rating)
                          .reduce((a, b) => a + b) /
                      reviews.length
                : 0.0;
            int calculatedReviewCount = reviews.length;

            // <<< ADD PRINT STATEMENT HERE >>>
            print(
              'ReviewsList: Calculated Rating: $calculatedAverageRating, Count: $calculatedReviewCount',
            );

            // Call the callback to update the parent's state
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.onRatingCalculated(
                calculatedAverageRating,
                calculatedReviewCount,
              );
            });

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 0,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              review.userName,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            RatingBarIndicator(
                              rating: review.rating,
                              itemBuilder: (context, index) => Icon(
                                Icons.star,
                                color: theme.colorScheme.secondary,
                              ),
                              itemCount: 5,
                              itemSize: 18.0,
                              direction: Axis.horizontal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'MMM d,yyyy',
                          ).format(review.timestamp.toDate()),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review.comment.isEmpty
                              ? 'No comment provided.'
                              : review.comment,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
