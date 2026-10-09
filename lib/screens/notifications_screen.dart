import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_colors.dart';
import '../data/advertisement.dart';
import '../data/advertisement_repository.dart';
import '../data/app_notification.dart';
import '../data/app_notification_repository.dart';
import '../data/placed_order.dart';
import '../widgets/main_bottom_navigation_bar.dart';
import '../state/orders_store.dart';
import '../widgets/curved_content_page.dart';
import 'categories_screen.dart';
import 'order_list_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.onNavigateTab,
    this.selectedTab = 0,
  });

  final ValueChanged<int>? onNavigateTab;
  final int selectedTab;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _filters = ['All', 'Orders', 'Promotion', 'System'];
  String _activeFilter = 'All';
  final Set<String> _readNotificationIds = {};
  final Set<String> _dismissedNotificationIds = {};
  late final Stream<List<Advertisement>> _advertisementStream;
  late final Stream<List<AppNotification>> _appNotificationStream;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _readSubscription;
  String? _userId;
  List<_NotificationItem> _latestNotifications = const [];
  bool _promotionErrorLogged = false;

  @override
  void initState() {
    super.initState();
    try {
      _advertisementStream = AdvertisementRepository().watchActive();
      _appNotificationStream = AppNotificationRepository().watchActive();
    } catch (error, stackTrace) {
      debugPrint('Unable to load promotion notifications: $error');
      _advertisementStream = Stream<List<Advertisement>>.error(
        error,
        stackTrace,
      ).asBroadcastStream();
      _appNotificationStream = Stream<List<AppNotification>>.error(
        error,
        stackTrace,
      ).asBroadcastStream();
    }

    try {
      _userId = FirebaseAuth.instance.currentUser?.uid;
      if (_userId case final userId?) {
        _readSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notificationReads')
            .where('isRead', isEqualTo: true)
            .snapshots()
            .listen(
              (snapshot) {
                if (!mounted) return;
                setState(() {
                  _readNotificationIds
                    ..clear()
                    ..addAll(snapshot.docs.map((document) => document.id));
                });
              },
              onError: (Object error, StackTrace _) {
                debugPrint('Unable to load notification read state: $error');
                if (mounted) _showReadStateError();
              },
            );
      }
    } catch (error) {
      debugPrint('Unable to initialize notification state: $error');
    }
  }

  @override
  void dispose() {
    _readSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: CurvedContentPage(
        title: 'Notifications',
        bottomNavigationBar: widget.onNavigateTab == null
            ? null
            : MainBottomNavigationBar(
                selectedIndex: widget.selectedTab,
                onTap: _navigateToTab,
              ),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
            color: Colors.white,
            icon: const Icon(Icons.done_all_rounded),
          ),
        ],
        body: StreamBuilder<List<AppNotification>>(
          stream: _appNotificationStream,
          builder: (context, appNotificationSnapshot) =>
              StreamBuilder<List<Advertisement>>(
                stream: _advertisementStream,
                builder: (context, promotionSnapshot) {
                  if (promotionSnapshot.hasError && !_promotionErrorLogged) {
                    _promotionErrorLogged = true;
                    debugPrint(
                      'Promotion notifications stream failed: '
                      '${promotionSnapshot.error}',
                    );
                  }
                  final ads = promotionSnapshot.data ?? const <Advertisement>[];
                  return ValueListenableBuilder<List<PlacedOrder>>(
                    valueListenable: OrdersStore.orders,
                    builder: (context, orders, _) {
                      final notifications = [
                        for (final notification
                            in appNotificationSnapshot.data ?? const [])
                          _NotificationItem(
                            id: 'notification-${notification.id}',
                            title: notification.title,
                            message: notification.message,
                            time: 'New',
                            type: notification.type,
                            icon: _iconForKey(notification.iconKey),
                          ),
                        for (final advertisement in ads)
                          _NotificationItem(
                            id: 'promotion-${advertisement.id}',
                            title: advertisement.title,
                            message: advertisement.description,
                            time: 'New promotion',
                            type: 'Promotion',
                            icon: Icons.local_offer_rounded,
                          ),
                        for (final order in orders)
                          _NotificationItem(
                            id: 'order-${order.id}',
                            title: 'Order ${order.status}',
                            message:
                                'Order ${order.formattedId} is ${order.status.toLowerCase()}.',
                            time: _dateLabel(order.createdAt),
                            type: 'Orders',
                            icon: Icons.receipt_long_rounded,
                          ),
                      ];
                      _latestNotifications = notifications;
                      final filteredItems = _activeFilter == 'All'
                          ? notifications
                          : notifications
                                .where((item) => item.type == _activeFilter)
                                .toList();
                      final items = filteredItems
                          .where(
                            (item) =>
                                !_dismissedNotificationIds.contains(item.id),
                          )
                          .toList();

                      return Column(
                        children: [
                          Container(
                            color: Colors.white,
                            height: 44,
                            child: Row(
                              children: [
                                for (final filter in _filters)
                                  Expanded(
                                    child: _NotificationFilter(
                                      label: filter,
                                      selected: filter == _activeFilter,
                                      onTap: () => setState(
                                        () => _activeFilter = filter,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (promotionSnapshot.hasError ||
                              appNotificationSnapshot.hasError)
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: Text(
                                'Live notifications could not be loaded.',
                                style: TextStyle(color: AppColors.textMuted),
                              ),
                            ),
                          Expanded(
                            child: items.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No notifications in this section',
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(14),
                                    itemCount: items.length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final item = items[index];
                                      final isRead = _readNotificationIds
                                          .contains(item.id);
                                      return Dismissible(
                                        key: ValueKey(item.id),
                                        direction: DismissDirection.endToStart,
                                        background: Container(
                                          alignment: Alignment.centerRight,
                                          padding: const EdgeInsets.only(
                                            right: 18,
                                          ),
                                          color: const Color(0xFFC62828),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.white,
                                          ),
                                        ),
                                        onDismissed: (_) => setState(
                                          () => _dismissedNotificationIds.add(
                                            item.id,
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                          leading: Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: AppColors.orangeTint,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              item.icon,
                                              color: AppColors.orange,
                                              size: 20,
                                            ),
                                          ),
                                          title: Text(
                                            item.title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.w800,
                                            ),
                                          ),
                                          subtitle: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              item.message,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textMuted,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                          trailing: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item.time,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.textMuted,
                                                ),
                                              ),
                                              Icon(
                                                isRead
                                                    ? Icons.check_circle_rounded
                                                    : Icons.circle,
                                                size: 10,
                                                color: isRead
                                                    ? AppColors.textMuted
                                                    : AppColors.orange,
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            if (!isRead) {
                                              unawaited(_markAsRead(item.id));
                                            }
                                            _openNotification(item);
                                          },
                                          onLongPress: () =>
                                              unawaited(_markAsRead(item.id)),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
        ),
      ),
    );
  }

  IconData _iconForKey(String key) => switch (key) {
    'coffee' => Icons.coffee_rounded,
    'cardGift' => Icons.card_giftcard_rounded,
    'localOffer' => Icons.local_offer_rounded,
    _ => Icons.notifications_rounded,
  };

  void _markAllAsRead() {
    final ids = _latestNotifications.map((item) => item.id).toSet();
    setState(() => _readNotificationIds.addAll(ids));
    unawaited(_persistReadIds(ids));
  }

  Future<void> _markAsRead(String id) async {
    if (_readNotificationIds.contains(id)) return;
    setState(() => _readNotificationIds.add(id));
    await _persistReadIds({id});
  }

  Future<void> _persistReadIds(Set<String> ids) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in ids) {
        final reference = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('notificationReads')
            .doc(id);
        batch.set(reference, {
          'isRead': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (error) {
      debugPrint('Unable to save notification read state: $error');
      if (!mounted) return;
      setState(() => _readNotificationIds.removeAll(ids));
      _showReadStateError();
    }
  }

  void _showReadStateError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not save notification read state.')),
    );
  }

  void _navigateToTab(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onNavigateTab?.call(index);
  }

  void _openNotification(_NotificationItem item) {
    if (item.type == 'Orders') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const OrderListScreen()));
    } else if (item.type == 'Promotion' || item.type == 'System') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const CategoriesScreen()));
    }
  }
}

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.month}/${local.day}/${local.year}';
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.icon,
  });

  final String id;
  final String title;
  final String message;
  final String time;
  final String type;
  final IconData icon;
}

class _NotificationFilter extends StatelessWidget {
  const _NotificationFilter({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.orange : AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ),
            Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: selected ? AppColors.orange : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
