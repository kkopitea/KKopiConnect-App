import 'package:cloud_firestore/cloud_firestore.dart';

import 'payment_method.dart';

class PaymentMethodRepository {
  PaymentMethodRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _paymentMethods =>
      _firestore.collection('paymentMethods');

  Stream<List<PaymentMethod>> watchActive() =>
      _paymentMethods.snapshots().map((snapshot) {
        if (snapshot.docs.isEmpty) return defaultPaymentMethods;
        final methods = snapshot.docs
            .map(
              (document) =>
                  PaymentMethod.fromFirestore(document.id, document.data()),
            )
            .whereType<PaymentMethod>()
            .where((method) => method.isActive)
            .toList();
        methods.sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          return byOrder == 0 ? a.name.compareTo(b.name) : byOrder;
        });
        return List.unmodifiable(methods);
      });

  Future<void> save(PaymentMethod method) async {
    if (method.id.trim().isEmpty || method.name.trim().isEmpty) {
      throw ArgumentError('Payment method id and name are required.');
    }
    await _paymentMethods.doc(method.id).set({
      'name': method.name.trim(),
      'isActive': method.isActive,
      'sortOrder': method.sortOrder,
      'instructions': method.instructions.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
