import 'package:cloud_firestore/cloud_firestore.dart';

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

  CollectionReference<Map<String, dynamic>> _ordersFor(String userId) =>
      _firestore.collection('users').doc(userId).collection('orders');

  @override
  Future<void> saveOrder(String userId, PlacedOrder order) async {
    await _ordersFor(userId).doc(order.id).set(order.toMap());
  }

  @override
  Stream<List<PlacedOrder>> watchOrders(String userId) {
    return _ordersFor(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => PlacedOrder.fromMap({
                  ...document.data(),
                  'id': document.id,
                }),
              )
              .toList(growable: false),
        );
  }

  @override
  Future<void> updateOrderStatus({
    required String userId,
    required String orderId,
    required String status,
  }) async {
    await _ordersFor(userId).doc(orderId).update({'status': status});
  }
}
