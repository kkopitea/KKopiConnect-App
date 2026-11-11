import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_colors.dart';
import '../data/advertisement.dart';
import '../data/advertisement_repository.dart';
import '../data/app_notification.dart';
import '../data/app_notification_repository.dart';
import '../data/placed_order.dart';
import '../data/order_repository.dart';
import '../services/advertisement_navigation.dart';
import '../widgets/main_bottom_navigation_bar.dart';
import '../state/orders_store.dart';
import '../widgets/curved_content_page.dart';
import 'notification_announcement_screen.dart';
import 'order_list_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.onNavigateTab,
    this.selectedTab = 0,
    this.advertisements,
    this.notifications,
    this.orderUpdates,
    this.onSelectCategory,
  });

  final ValueChanged<int>? onNavigateTab;
  final int selectedTab;
  final Stream<List<Advertisement>>? advertisements;
  final Stream<List<AppNotification>>? notifications;
  final Stream<List<PlacedOrder>>? orderUpdates;
  final ValueChanged<String>? onSelectCategory;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _filters = ['All', 'Orders', 'Promotion', 'System'];
  static const _guestDismissedNotificationsKey = 'dismissedNotifications_guest';
  String _activeFilter = 'All';
  final Set<String> _readNotificationIds = {};
  final Set<String> _dismissedNotificationIds = {};
  late Stream<List<Advertisement>> _advertisementStream;
  late Stream<List<AppNotification>> _appNotificationStream;
  Stream<List<PlacedOrder>>? _orderStream;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _readSubscription;
  StreamSubscription<List<PlacedOrder>>? _orderSubscription;
  String? _userId;
  List<PlacedOrder> _savedOrders = const [];
  List<_NotificationItem> _latestNotifications = const [];
  bool _promotionErrorLogged = false;

  @override
  void initState() {
    super.initState();
    OrdersStore.orders.addListener(_ordersChanged);
    try {
      _advertisementStream =
          widget.advertisements ?? AdvertisementRepository().watchActive();
      _appNotificationStream =
          widget.notifications ?? AppNotificationRepository().watchActive();
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
        _orderStream =
            widget.orderUpdates ??
            FirestoreOrderRepository().watchOrders(userId);
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
                  _dismissedNotificationIds.addAll(
                    snapshot.docs
                        .where(
                          (document) => document.data()['isDismissed'] == true,
                        )
                        .map((document) => document.id),
                  );
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
    unawaited(_loadLocallyDismissedIds());
    _orderStream ??= widget.orderUpdates;
    _orderSubscription = _orderStream?.listen(
      (orders) {
        if (!mounted) return;
        setState(() => _savedOrders = orders);
      },
      onError: (Object error) {
        debugPrint('Unable to load order notifications: $error');
      },
    );
  }

  @override
  void dispose() {
    OrdersStore.orders.removeListener(_ordersChanged);
    _readSubscription?.cancel();
    _orderSubscription?.cancel();
    super.dispose();
  }

  void _ordersChanged() {
    if (mounted) setState(() {});
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
                  final orders = _mergeOrders(
                    OrdersStore.orders.value,
                    _savedOrders,
                  );
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
                        imageUrls: [
                          if (notification.imageUrl.isNotEmpty)
                            notification.imageUrl,
                        ],
                        version: notification.version,
                      ),
                    for (final advertisement in ads)
                      _NotificationItem(
                        id: 'promotion-${advertisement.id}',
                        title: advertisement.title,
                        message: advertisement.description,
                        time: 'New promotion',
                        type: 'Promotion',
                        icon: Icons.local_offer_rounded,
                        imageUrls: advertisement.campaignImageUrls,
                        eyebrow: advertisement.eyebrow,
                        buttonLabel: advertisement.buttonLabel,
                        startAt: advertisement.startAt,
                        endAt: advertisement.endAt,
                        advertisement: advertisement,
                      ),
                    for (final order in orders)
                      _NotificationItem(
                        id: 'order-${order.id}',
                        title: 'Order ${order.status}',
                        message: _orderMessage(order),
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
                        (item) => !_dismissedNotificationIds.contains(item.id),
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
                                  onTap: () =>
                                      setState(() => _activeFilter = filter),
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
                        child: RefreshIndicator(
                          onRefresh: _refreshNotifications,
                          child: items.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.sizeOf(context).height *
                                          0.55,
                                      child: const Center(
                                        child: Text(
                                          'No notifications in this section',
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
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
                                      onDismissed: (_) =>
                                          _dismissNotification(item.id),
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
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                      ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }

  Future<void> _refreshNotifications() async {
    try {
      final advertisements =
          widget.advertisements ?? AdvertisementRepository().watchActive();
      final notifications =
          widget.notifications ?? AppNotificationRepository().watchActive();
      if (!mounted) return;
      setState(() {
        _advertisementStream = advertisements;
        _appNotificationStream = notifications;
        _promotionErrorLogged = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Unable to refresh notifications: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not refresh notifications.')),
        );
      }
    }
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

  void _dismissNotification(String id) {
    if (_dismissedNotificationIds.contains(id)) return;
    setState(() => _dismissedNotificationIds.add(id));
    unawaited(_persistDismissedIds({id}));
  }

  Future<void> _persistDismissedIds(Set<String> ids) async {
    try {
      await _archiveLocally(ids);
    } catch (error) {
      debugPrint('Unable to archive notification on this device: $error');
      if (mounted) _showDismissalError();
      return;
    }

    final userId = _userId;
    if (userId == null) {
      _showArchivedConfirmation();
      return;
    }

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
          'isDismissed': true,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (error) {
      debugPrint('Unable to save dismissed notifications: $error');
      _showArchivedConfirmation();
    }
  }

  Future<void> _loadLocallyDismissedIds() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final ids = preferences.getStringList(_dismissedNotificationsKey) ?? [];
      if (!mounted || ids.isEmpty) return;
      setState(() => _dismissedNotificationIds.addAll(ids));
    } catch (error) {
      debugPrint('Unable to load locally archived notifications: $error');
    }
  }

  Future<void> _archiveLocally(Set<String> ids) async {
    final preferences = await SharedPreferences.getInstance();
    final archivedIds =
        preferences.getStringList(_dismissedNotificationsKey)?.toSet() ??
        <String>{};
    archivedIds.addAll(ids);
    await preferences.setStringList(
      _dismissedNotificationsKey,
      archivedIds.toList(),
    );
  }

  void _showArchivedConfirmation() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification archived on this device.')),
    );
  }

  String get _dismissedNotificationsKey {
    final userId = _userId;
    return userId == null
        ? _guestDismissedNotificationsKey
        : 'dismissedNotifications_$userId';
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

  void _showDismissalError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not archive the notification on this device.'),
      ),
    );
  }

  void _navigateToTab(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onNavigateTab?.call(index);
  }

  void _openNotification(_NotificationItem item) {
    if (item.type == 'Orders') {
      if (widget.onNavigateTab != null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        widget.onNavigateTab!(3);
      } else {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const OrderListScreen()),
        );
      }
    } else if (item.type == 'Promotion' || item.type == 'System') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NotificationAnnouncementScreen(
            title: item.title,
            message: item.message,
            type: item.type,
            imageUrls: item.imageUrls,
            eyebrow: item.eyebrow,
            version: item.version,
            buttonLabel: item.buttonLabel,
            promotionDates: _promotionDateLabel(item.startAt, item.endAt),
            onAction: item.type == 'Promotion' && item.advertisement != null
                ? () {
                    final navigator = Navigator.of(context);
                    final actionType =
                        item.advertisement!.effectiveButtonActionType;
                    if (actionType == 'product' ||
                        (actionType == 'category' &&
                            widget.onSelectCategory == null)) {
                      navigator.pop();
                    } else {
                      navigator.popUntil((route) => route.isFirst);
                    }
                    AdvertisementNavigation.open(
                      navigator.context,
                      item.advertisement!,
                      onNavigateTab: widget.onNavigateTab,
                      onSelectCategory: widget.onSelectCategory,
                    );
                  }
                : null,
          ),
        ),
      );
    }
  }
}

List<PlacedOrder> _mergeOrders(
  List<PlacedOrder> localOrders,
  List<PlacedOrder> savedOrders,
) {
  final ordersById = <String, PlacedOrder>{
    for (final order in savedOrders) order.id: order,
  };
  for (final order in localOrders) {
    ordersById.putIfAbsent(order.id, () => order);
  }
  return ordersById.values.toList()
    ..sort((first, second) => second.createdAt.compareTo(first.createdAt));
}

String _orderMessage(PlacedOrder order) {
  final orderedItems = order.items
      .map((item) => '${item.product.name} × ${item.quantity}')
      .join(' · ');
  final status =
      '${order.fulfillmentLabel} order is ${order.status.toLowerCase()}.';
  return orderedItems.isEmpty ? status : '$orderedItems · $status';
}

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.month}/${local.day}/${local.year}';
}

String _promotionDateLabel(DateTime? startAt, DateTime? endAt) {
  String label(DateTime date) {
    final local = date.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }

  if (startAt == null && endAt == null) return '';
  if (startAt != null && endAt != null) {
    return 'Valid ${label(startAt)} – ${label(endAt)}';
  }
  if (startAt != null) return 'Starts ${label(startAt)}';
  return 'Ends ${label(endAt!)}';
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.icon,
    this.imageUrls = const [],
    this.eyebrow = '',
    this.version = '',
    this.buttonLabel = '',
    this.startAt,
    this.endAt,
    this.advertisement,
  });

  final String id;
  final String title;
  final String message;
  final String time;
  final String type;
  final IconData icon;
  final List<String> imageUrls;
  final String eyebrow;
  final String version;
  final String buttonLabel;
  final DateTime? startAt;
  final DateTime? endAt;
  final Advertisement? advertisement;
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
