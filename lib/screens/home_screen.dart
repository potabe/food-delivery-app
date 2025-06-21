// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_app/models/restaurant.dart';
import 'package:food_app/screens/restaurant_details_screen.dart';
import 'package:food_app/screens/user_profile_screen.dart';
import 'package:food_app/screens/order_history_screen.dart';
// Removed: import 'package:food_app/screens/favorite_restaurants_screen.dart';
import 'package:food_app/models/app_user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  // Removed: _toggleFavorite method is no longer here

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final theme = Theme.of(context);

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UserProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          // Removed: Favorite Restaurants Icon is no longer here
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: theme.primaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: _firestore
                      .collection('users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    String displayName = 'User';
                    if (snapshot.connectionState == ConnectionState.active &&
                        snapshot.hasData) {
                      final appUser = AppUser.fromFirestore(
                        snapshot.data!,
                        null,
                      );
                      displayName = appUser.name.isNotEmpty
                          ? appUser.name
                          : (user.email?.split('@')[0] ?? 'User');
                    } else if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      displayName = 'Loading...';
                    }
                    return Text(
                      'Hello, $displayName!',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Find your favorite food today!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search for restaurants...',
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1.0,
                      ),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  cursorColor: Colors.white,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Popular Restaurants',
              style: theme.textTheme.titleLarge,
            ),
          ),
          Expanded(
            // Reverted to original StreamBuilder structure
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _searchQuery.isEmpty
                  ? _firestore.collection('restaurants').snapshots()
                  : _firestore
                        .collection('restaurants')
                        .where('name', isGreaterThanOrEqualTo: _searchQuery)
                        .where(
                          'name',
                          isLessThanOrEqualTo: _searchQuery + '\uf8ff',
                        )
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
                          Icons.store_mall_directory_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No restaurants found at the moment.'
                              : 'No restaurants matching "$_searchQuery" found.',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Try a different name or browse all restaurants.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Clear Search'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                final restaurants = snapshot.data!.docs.map((doc) {
                  return Restaurant.fromFirestore(doc, null);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    // Removed: isFavorited check is no longer here

                    return Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => RestaurantDetailsScreen(
                                restaurant: restaurant,
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Removed: Stack for favorite button overlay
                            ClipRRect(
                              // Directly use ClipRRect
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              child: Image.network(
                                restaurant.imageUrl,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 180,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Removed: Positioned favorite button is no longer here
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    restaurant.name,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${restaurant.rating}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(
                                        Icons.delivery_dining,
                                        color: Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        restaurant.deliveryTime,
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
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
          ),
        ],
      ),
    );
  }
}
