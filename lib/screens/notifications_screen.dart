import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/placed_order.dart';
import '../state/orders_store.dart';
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

  static const _announcements = <_NotificationItem>[
    _NotificationItem(
      title: 'Special Promo',
      message: 'Get 10% off your next order.',
      time: 'Yesterday',
      type: 'Promotion',
      icon: Icons.local_offer_rounded,
    ),
    _NotificationItem(
      title: 'New Menu',
      message: 'Try the new Brown Sugar Pearl Latte.',
      time: 'Sep 24',
      type: 'System',
      icon: Icons.coffee_rounded,
    ),
    _NotificationItem(
      title: 'Loyalty Reward',
      message: 'You have earned 20 points this week.',
      time: 'Sep 20',
      type: 'Promotion',
      icon: Icons.card_giftcard_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<PlacedOrder>>(
        valueListenable: OrdersStore.orders,
        builder: (context, orders, _) {
          final notifications = [
            ..._announcements,
            for (final order in orders)
              _NotificationItem(
                title: 'Order ${order.status}',
                message:
                    'Order ${order.formattedId} is ${order.status.toLowerCase()}.',
                time: _dateLabel(order.createdAt),
                type: 'Orders',
                icon: Icons.receipt_long_rounded,
              ),
          ];
          final items = _activeFilter == 'All'
              ? notifications
              : notifications
                    .where((item) => item.type == _activeFilter)
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
                          return ListTile(
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
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                item.message,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            trailing: Text(
                              item.time,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textMuted,
                              ),
                            ),
                            onTap: () => _openNotification(item),
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
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.icon,
  });

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
