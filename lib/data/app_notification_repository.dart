import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_notification.dart';

class AppNotificationRepository {
  AppNotificationRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  Stream<List<AppNotification>> watchActive() =>
      _notifications.snapshots().map((snapshot) {
        final notifications = snapshot.docs
            .map(
              (document) =>
                  AppNotification.fromFirestore(document.id, document.data()),
            )
            .whereType<AppNotification>()
            .where((notification) => notification.isActive)
            .toList();
        notifications.sort((a, b) {
          final byOrder = a.sortOrder.compareTo(b.sortOrder);
          return byOrder == 0 ? a.title.compareTo(b.title) : byOrder;
        });
        return List.unmodifiable(notifications);
      });

  Future<void> save(AppNotification notification) async {
    if (notification.id.isEmpty ||
        notification.title.trim().isEmpty ||
        notification.message.trim().isEmpty) {
      throw ArgumentError(
        'Notification id, title, and message are required.',
      );
    }
    await _notifications.doc(notification.id).set({
      'title': notification.title.trim(),
      'message': notification.message.trim(),
      'type': notification.type,
      'isActive': notification.isActive,
      'sortOrder': notification.sortOrder,
      'iconKey': notification.iconKey,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
