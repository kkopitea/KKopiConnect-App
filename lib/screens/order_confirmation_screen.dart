import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/placed_order.dart';
import 'order_list_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.order,
    this.onNavigateTab,
  });

  final PlacedOrder order;
  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final orderLabel = order.items.length == 1
        ? order.items.first.product.name
        : '${order.items.first.product.name} + ${order.items.length - 1} more';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
              children: [
                const Text(
                  'Order Confirmed',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 18),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 245,
                      child: Stack(
                        children: [
                          const Positioned(
                            left: 18,
                            top: 40,
                            child: Icon(
                              Icons.star_rounded,
                              color: AppColors.orange,
                              size: 22,
                            ),
                          ),
                          const Positioned(
                            right: 26,
                            top: 28,
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.orange,
                              size: 19,
                            ),
                          ),
                          const Positioned(
                            left: 48,
                            bottom: 38,
                            child: Icon(
                              Icons.circle,
                              color: AppColors.orange,
                              size: 8,
                            ),
                          ),
                          const Positioned(
                            right: 44,
                            bottom: 48,
                            child: Icon(
                              Icons.star_rounded,
                              color: AppColors.orange,
                              size: 13,
                            ),
                          ),
                          const Center(
                            child: Image(
                              image: AssetImage(
                                'assets/images/kkopitea_drink.png',
                              ),
                              width: 205,
                              height: 230,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 68,
                      bottom: 24,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Thank you!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$orderLabel has been placed successfully.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Order ${order.formattedId} · P${order.total}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '${order.fulfillment} · ${order.paymentMethod}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    if (onNavigateTab != null) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      onNavigateTab!(3);
                    } else {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const OrderListScreen(),
                        ),
                        (route) => route.isFirst,
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  child: const Text(
                    'View my orders',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text(
                    'Back to home',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
