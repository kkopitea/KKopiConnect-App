import 'package:flutter/material.dart';

import '../app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'Order Update', 'subtitle': 'Your order #1239-2026-KK51 now is preparing.', 'time': '10:31 AM', 'type': 'order'},
      {'title': 'Special Promo', 'subtitle': 'Get 10% off on your next order.', 'time': 'Yesterday', 'type': 'promo'},
      {'title': 'New Menu', 'subtitle': 'Try the new Brown Sugar Pearl Latte.', 'time': 'July 23', 'type': 'menu'},
      {'title': 'Loyalty Reward', 'subtitle': 'You have earned 20 points for this week.', 'time': 'July 10', 'type': 'reward'},
    ];

    final tabs = ['All', 'Orders', 'Promotion', 'System'];

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1080,
              maxHeight: 2400,
            ),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Expanded(
                        child: Text(
                          'Notifications',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                ),
                Container(
                  color: AppColors.orange,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Row(
                    children: tabs.map((tab) {
                      final active = tab == 'Orders';
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: active ? Colors.white : const Color(0xFFFF9E42),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            tab,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: active ? AppColors.orange : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final type = item['type'] as String;
                      final icon = switch (type) {
                        'order' => Icons.receipt_long_rounded,
                        'promo' => Icons.local_offer_rounded,
                        'menu' => Icons.coffee_rounded,
                        _ => Icons.card_giftcard_rounded,
                      };

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['subtitle'] as String,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF666666),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item['time'] as String,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF666666),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _navItem(Icons.home_rounded, 'Home', false),
                      _navItem(Icons.category_rounded, 'Categories', false),
                      _navItem(Icons.shopping_bag_outlined, 'Cart', false),
                      _navItem(Icons.receipt_long_rounded, 'Orders', false),
                      _navItem(Icons.settings_rounded, 'Settings', false),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _navItem(IconData icon, String label, bool active) {
    return Column(
      children: [
        Icon(icon, color: active ? AppColors.orange : AppColors.iconMuted, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: active ? AppColors.orange : AppColors.iconMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
