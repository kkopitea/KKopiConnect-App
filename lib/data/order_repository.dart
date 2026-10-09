import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'placed_order.dart';

abstract interface class OrderRepository {
  Future<void> saveOrder(String userId, PlacedOrder order);

  Stream<List<PlacedOrder>> watchOrders(String userId);

  Future<void> updateOrderStatus({
    required String userId,
    required String orderId,
    required String status,
  });
}

class FirestoreOrderRepository implements OrderRepository {
  FirestoreOrderRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  @override
  Future<void> saveOrder(String userId, PlacedOrder order) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != userId) {
      throw StateError('Sign in before placing an order.');
    }
    await _orders.doc(order.id).set({
      ...order.toMap(),
      'orderId': order.id,
      'orderType': order.fulfillment,
      'userId': userId,
      'customerId': userId,
      'customerName': user.displayName ?? 'Customer',
      'customerEmail': user.email ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<PlacedOrder>> watchOrders(String userId) {
    return _orders
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map(
                (document) => PlacedOrder.fromMap({
                  ...document.data(),
                  'id': document.id,
                }),
              )
              .toList();
          orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return List.unmodifiable(orders);
        });
  }

  @override
  Future<void> updateOrderStatus({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != userId) {
      throw StateError('You can only update your own order.');
    }
    if (status != 'Cancelled') {
      throw ArgumentError.value(status, 'status', 'Only cancellation is allowed.');
    }
    await _orders.doc(orderId).update({'status': status});
  }
}
