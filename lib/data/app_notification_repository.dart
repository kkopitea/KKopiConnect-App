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
    final normalizedType = notification.type.trim().toLowerCase();
    if (notification.id.isEmpty ||
        notification.title.trim().isEmpty ||
        notification.message.trim().isEmpty ||
        notification.title.trim().length > 128 ||
        notification.message.trim().length > 2000 ||
        !const {'promotion', 'system'}.contains(normalizedType) ||
        notification.imageUrl.trim().length > 2048 ||
        notification.version.trim().length > 50 ||
        !const {
          'notifications',
          'coffee',
          'cardGift',
          'localOffer',
        }.contains(notification.iconKey)) {
      throw ArgumentError(
        'Notification fields are invalid or exceed supported limits.',
      );
    }
    await _notifications.doc(notification.id).set({
      'title': notification.title.trim(),
      'message': notification.message.trim(),
      'type': normalizedType == 'promotion' ? 'Promotion' : 'System',
      'isActive': notification.isActive,
      'sortOrder': notification.sortOrder,
      'iconKey': notification.iconKey,
      'imageUrl': notification.imageUrl.trim(),
      'version': notification.version.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
