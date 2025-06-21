// lib/screens/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:food_app/models/order.dart' as app_order; // Use the prefix
// import 'package:food_app/models/order_item.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _auth = FirebaseAuth.instance;
    final _firestore = FirebaseFirestore.instance;
    final theme = Theme.of(context);
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order History')),
        body: Center(
          child: Text(
            'Please log in to view your order history.',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('orders')
            .where('userId', isEqualTo: currentUser.uid)
            .orderBy('orderDate', descending: true)
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
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No past orders found.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Place your first order now!',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data!.docs.map((doc) {
            return app_order.Order.fromFirestore(doc, null);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Dismissible(
                // <<< BEGIN DISMISSIBLE WIDGET >>>
                key: ValueKey(order.orderId), // Unique key for the Dismissible
                direction:
                    DismissDirection.endToStart, // Swipe from right to left
                background: Container(
                  color: theme.colorScheme.error, // Red background for delete
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.symmetric(
                    vertical: 8,
                  ), // Match card margin
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                confirmDismiss: (direction) {
                  // Show a confirmation dialog before deleting
                  return showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Confirm Deletion'),
                      content: const Text(
                        'Are you sure you want to delete this order from your history?',
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('No'),
                          onPressed: () {
                            Navigator.of(ctx).pop(false); // Do not dismiss
                          },
                        ),
                        TextButton(
                          child: const Text('Yes'),
                          onPressed: () {
                            Navigator.of(ctx).pop(true); // Dismiss
                          },
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) async {
                  // --- DELETION LOGIC ---
                  try {
                    await _firestore
                        .collection('orders')
                        .doc(order.orderId)
                        .delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Order #${order.orderId.substring(0, 8).toUpperCase()} deleted.',
                        ),
                      ),
                    );
                  } catch (e) {
                    print('Error deleting order: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete order: $e'),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                  // --- END DELETION LOGIC ---
                },
                child: Card(
                  // The actual order card being dismissed
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order.orderId.substring(0, 8).toUpperCase()}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat(
                                'MMM d,EEEE - hh:mm a',
                              ).format(order.orderDate.toDate()), // Format date
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'From: ${order.restaurantName}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Status: ${order.status}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: order.status == 'Delivered'
                                ? Colors.green[700]
                                : Colors.orange[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Divider(height: 20, thickness: 1),
                        Text('Items:', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        ...order.items
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                  horizontal: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${item.quantity}x',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.name,
                                        style: theme.textTheme.bodyMedium,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),
                ),
              ); // <<< END DISMISSIBLE WIDGET >>>
            },
          );
        },
      ),
    );
  }
}
