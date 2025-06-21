// lib/widgets/restaurant_menu_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:food_app/models/food_item.dart';
import 'package:food_app/providers/cart_provider.dart';

class RestaurantMenuList extends StatelessWidget {
  final String restaurantId;

  const RestaurantMenuList({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    final _firestore = FirebaseFirestore.instance;
    final cart = Provider.of<CartProvider>(context, listen: false);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Menu Items', style: theme.textTheme.titleLarge),
        ),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('restaurants')
              .doc(restaurantId)
              .collection('menuItems')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No menu items available yet!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This restaurant might be updating its menu.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final menuItems = snapshot.data!.docs.map((doc) {
              return FoodItem.fromFirestore(doc, null);
            }).toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.network(
                            item.imageUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                height: 100,
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.description,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[700],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '\$${item.price.toStringAsFixed(2)}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(color: theme.primaryColor),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      cart.addItem(item);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${item.name} added to cart!',
                                          ),
                                          duration: const Duration(
                                            milliseconds: 800,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.add_shopping_cart,
                                      size: 20,
                                    ),
                                    label: const Text('Add'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      textStyle: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
