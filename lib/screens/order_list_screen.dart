import 'package:flutter/material.dart';

import '../app_colors.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = [
      {'id': 'Order #0004', 'status': 'Pending', 'price': 'P50.00', 'date': 'Today'},
      {'id': 'Order #0003', 'status': 'Completed', 'price': 'P100.00', 'date': '2 days ago'},
      {'id': 'Order #0002', 'status': 'Preparing', 'price': 'P120.00', 'date': '3 days ago'},
      {'id': 'Order #0001', 'status': 'Cancelled', 'price': 'P80.00', 'date': '4 days ago'},
    ];

    return Scaffold(
      backgroundColor: AppColors.orange,
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
                color: Colors.transparent,
              ),
              child: Column(
                children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (Navigator.canPop(context)) Navigator.pop(context);
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Expanded(
                        child: Text(
                          'Order List',
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
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                      final order = orders[index];
                      final status = order['status'] as String;
                      final statusColor = switch (status) {
                        'Pending' => const Color(0xFFFFF1E6),
                        'Preparing' => const Color(0xFFFFF0B3),
                        'Completed' => const Color(0xFFE8F7E8),
                        _ => const Color(0xFFF3E5E5),
                      };
                      final statusTextColor = switch (status) {
                        'Pending' => AppColors.orange,
                        'Preparing' => const Color(0xFFB76B00),
                        'Completed' => const Color(0xFF2E7D32),
                        _ => const Color(0xFFC62828),
                      };

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8E8E8)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5EAD7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Image.asset(
                                  'assets/images/welcome_drink.png',
                                  width: 32,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          order['id'] as String,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: statusTextColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Order from ${order['date']}',
                                    style: const TextStyle(
                                      color: Color(0xFF666666),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        order['price'] as String,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          backgroundColor: AppColors.orange,
                                        ),
                                        child: const Text(
                                          'View Details',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                      },
                    ),
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

}
