import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'order_number.dart';
import 'placed_order.dart';

abstract interface class OrderRepository {
  Future<PlacedOrder> saveOrder(
    String userId,
    PlacedOrder order, {
    required String customerName,
  });

  Stream<List<PlacedOrder>> watchOrders(String userId);

  Future<void> deleteOrders({
    required String userId,
    required List<String> orderIds,
  });

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
  Future<PlacedOrder> saveOrder(
    String userId,
    PlacedOrder order, {
    required String customerName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != userId) {
      throw StateError('Sign in before placing an order.');
    }
    final normalizedName = customerName.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError.value(
        customerName,
        'customerName',
        'Name is required.',
      );
    }
    final counter = _firestore.collection('metadata').doc('orderCounter');
    return _firestore.runTransaction((transaction) async {
      final counterSnapshot = await transaction.get(counter);
      final counterValue = counterSnapshot.data()?['value'];
      if (counterSnapshot.exists && counterValue is! int) {
        throw StateError('The order number counter is invalid.');
      }

      final serial = (counterValue as int? ?? 0) + 1;
      final orderId = formatOrderNumber(serial);
      final savedOrder = order.copyWith(id: orderId);
      transaction.set(counter, {'value': serial});
      transaction.set(_orders.doc(orderId), {
        ...savedOrder.toMap(),
        'orderId': orderId,
        'orderType': savedOrder.fulfillment,
        'userId': userId,
        'customerId': userId,
        'customerName': normalizedName,
        'customerEmail': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return savedOrder;
    });
  }

  @override
  Stream<List<PlacedOrder>> watchOrders(String userId) {
    return _orders.where('userId', isEqualTo: userId).snapshots().map((
      snapshot,
    ) {
      final orders =
          snapshot.docs
              .map(
                (document) => PlacedOrder.fromMap({
                  ...document.data(),
                  'id': document.id,
                }),
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(orders);
    });
  }

  @override
  Future<void> deleteOrders({
    required String userId,
    required List<String> orderIds,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.uid != userId) {
      throw StateError('You can only delete your own orders.');
    }
    if (orderIds.isEmpty) return;
    final uniqueOrderIds = orderIds.toSet().toList();
    for (var start = 0; start < uniqueOrderIds.length; start += 500) {
      final batch = _firestore.batch();
      final end = (start + 500).clamp(0, uniqueOrderIds.length);
      for (final orderId in uniqueOrderIds.sublist(start, end)) {
        batch.delete(_orders.doc(orderId));
      }
      await batch.commit();
    }
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
      throw ArgumentError.value(
        status,
        'status',
        'Only cancellation is allowed.',
      );
    }
    await _orders.doc(orderId).update({'status': status});
  }
}
