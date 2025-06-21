// lib/screens/cart_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_app/providers/cart_provider.dart';
import 'package:food_app/models/order.dart'
    as app_order; // <<< CHANGED: Added 'as app_order'
import 'package:food_app/models/order_item.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final theme = Theme.of(context);
    final _auth = FirebaseAuth.instance;
    final _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(15),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total:', style: theme.textTheme.titleLarge),
                  const SizedBox(width: 10),
                  Chip(
                    label: Text(
                      '\$${cart.totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.labelLarge?.copyWith(fontSize: 18),
                    ),
                    backgroundColor: theme.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: cart.itemCount > 0 && _auth.currentUser != null
                        ? () async {
                            try {
                              final List<OrderItem> orderItems = cart.items.map(
                                (cartItem) {
                                  return OrderItem(
                                    foodItemId: cartItem.foodItem.id,
                                    name: cartItem.foodItem.name,
                                    price: cartItem.foodItem.price,
                                    quantity: cartItem.quantity,
                                    imageUrl: cartItem.foodItem.imageUrl,
                                  );
                                },
                              ).toList();

                              String restaurantName = 'User\'s Order';
                              if (orderItems.isNotEmpty) {
                                if (orderItems.first.name.contains('Pizza')) {
                                  restaurantName = 'Pizza Paradise';
                                } else if (orderItems.first.name.contains(
                                  'Burger',
                                )) {
                                  restaurantName = 'Burger Joint';
                                }
                              }

                              // <<< CHANGED: Use app_order.Order here
                              final newOrder = app_order.Order(
                                // <<< Use app_order.Order
                                orderId: '',
                                userId: _auth.currentUser!.uid,
                                restaurantName: restaurantName,
                                items: orderItems,
                                totalAmount: cart.totalAmount,
                                orderDate: Timestamp.now(),
                                status: 'Delivered',
                              );

                              await _firestore
                                  .collection('orders')
                                  .add(newOrder.toFirestore());

                              cart.clearCart();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Order placed successfully! Total: \$${newOrder.totalAmount.toStringAsFixed(2)}',
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                              Navigator.of(context).pop();
                            } catch (e) {
                              print('Error placing order: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to place order: $e'),
                                  backgroundColor: theme.colorScheme.error,
                                ),
                              );
                            }
                          }
                        : null,
                    child: const Text('ORDER NOW'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(120, 45),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your cart is empty. Start adding some delicious food!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.restaurant_menu),
                          label: const Text('Browse Restaurants'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final cartItem = cart.items[index];
                      return Dismissible(
                        key: ValueKey(cartItem.foodItem.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: theme.colorScheme.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 4,
                          ),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        confirmDismiss: (direction) {
                          return showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Are you sure?'),
                              content: const Text(
                                'Do you want to remove the item from the cart?',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('No'),
                                  onPressed: () {
                                    Navigator.of(ctx).pop(false);
                                  },
                                ),
                                TextButton(
                                  child: const Text('Yes'),
                                  onPressed: () {
                                    Navigator.of(ctx).pop(true);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          cart.removeItem(cartItem.foodItem.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${cartItem.foodItem.name} removed from cart.',
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 4,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      cartItem.foodItem.imageUrl,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.broken_image,
                                                color: Colors.grey,
                                              ),
                                            );
                                          },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        cartItem.foodItem.name,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Price: \$${cartItem.foodItem.price.toStringAsFixed(2)}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      'Qty: ${cartItem.quantity}',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(fontSize: 14),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          iconSize: 20,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          color: theme.primaryColor,
                                          onPressed: () {
                                            cart.decreaseQuantity(
                                              cartItem.foodItem.id,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                          iconSize: 20,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          color: theme.primaryColor,
                                          onPressed: () {
                                            cart.increaseQuantity(
                                              cartItem.foodItem.id,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
