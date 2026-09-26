import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/placed_order.dart';
import '../state/orders_store.dart';
import '../widgets/curved_content_page.dart';
import 'categories_screen.dart';
import 'order_list_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _filters = ['All', 'Orders', 'Promotion', 'System'];
  String _activeFilter = 'All';
  final Set<String> _readNotificationIds = {};
  final Set<String> _dismissedNotificationIds = {};

  static const _announcements = <_NotificationItem>[
    _NotificationItem(
      id: 'promotion-special',
      title: 'Special Promo',
      message: 'Get 10% off your next order.',
      time: 'Yesterday',
      type: 'Promotion',
      icon: Icons.local_offer_rounded,
    ),
    _NotificationItem(
      id: 'system-menu',
      title: 'New Menu',
      message: 'Try the new Brown Sugar Pearl Latte.',
      time: 'Sep 24',
      type: 'System',
      icon: Icons.coffee_rounded,
    ),
    _NotificationItem(
      id: 'promotion-loyalty',
      title: 'Loyalty Reward',
      message: 'You have earned 20 points this week.',
      time: 'Sep 20',
      type: 'Promotion',
      icon: Icons.card_giftcard_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CurvedContentPage(
      title: 'Notifications',
      actions: [
        IconButton(
          tooltip: 'Mark all as read',
          onPressed: _markAllAsRead,
          color: Colors.white,
          icon: const Icon(Icons.done_all_rounded),
        ),
      ],
      body: ValueListenableBuilder<List<PlacedOrder>>(
        valueListenable: OrdersStore.orders,
        builder: (context, orders, _) {
          final notifications = [
            ..._announcements,
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
          final filteredItems = _activeFilter == 'All'
              ? notifications
              : notifications
                    .where((item) => item.type == _activeFilter)
                    .toList();
          final items = filteredItems
              .where((item) => !_dismissedNotificationIds.contains(item.id))
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
                          onTap: () => setState(() => _activeFilter = filter),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: items.isEmpty
                    ? const Center(
                        child: Text('No notifications in this section'),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isRead = _readNotificationIds.contains(item.id);
                          return Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 18),
                              color: const Color(0xFFC62828),
                              child: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.white,
                              ),
                            ),
                            onDismissed: (_) => setState(
                              () => _dismissedNotificationIds.add(item.id),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.orangeTint,
                                  borderRadius: BorderRadius.circular(12),
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
                                padding: const EdgeInsets.only(top: 4),
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                setState(() {
                                  if (isRead) {
                                    _readNotificationIds.remove(item.id);
                                  } else {
                                    _readNotificationIds.add(item.id);
                                  }
                                });
                                _openNotification(item);
                              },
                              onLongPress: () => setState(
                                () => _readNotificationIds.add(item.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      _readNotificationIds.addAll(_announcements.map((item) => item.id));
      _readNotificationIds.addAll(
        OrdersStore.orders.value.map((order) => 'order-${order.id}'),
      );
    });
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
