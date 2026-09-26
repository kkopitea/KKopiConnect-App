import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/placed_order.dart';
import '../state/orders_store.dart';
import '../widgets/cloudinary_image.dart';
import 'categories_screen.dart';

class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<PlacedOrder>>(
        valueListenable: OrdersStore.orders,
        builder: (context, orders, _) {
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_rounded,
                      size: 44,
                      color: AppColors.orange,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No orders yet',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your placed orders will appear here.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CategoriesScreen(),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Browse menu'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) => _OrderCard(
              order: orders[index],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => OrderDetailsScreen(order: orders[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final PlacedOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstProduct = order.items.isEmpty ? null : order.items.first.product;
    final name = order.items.length == 1
        ? order.items.first.product.name
        : '${order.items.first.product.name} + ${order.items.length - 1} more';
    final statusColor = _statusColor(order.status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: firstProduct == null
                    ? const SizedBox(
                        width: 54,
                        height: 54,
                        child: Icon(Icons.local_cafe_rounded),
                      )
                    : CloudinaryImage(
                        url: firstProduct.imageUrl,
                        fallbackAsset: firstProduct.imageAsset,
                        width: 54,
                        height: 54,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.formattedId,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(order.createdAt)} · P${order.total}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({super.key, required this.order});

  final PlacedOrder order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<PlacedOrder>>(
        valueListenable: OrdersStore.orders,
        builder: (context, orders, _) {
          final matchingOrders = orders.where((item) => item.id == order.id);
          final current = matchingOrders.isEmpty ? order : matchingOrders.first;
          final statusColor = _statusColor(current.status);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _panelDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            current.formattedId,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Text(
                            current.status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatDate(current.createdAt)} · ${current.fulfillment}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    Text(
                      'Payment: ${current.paymentMethod}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    if (current.instructions.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Note: ${current.instructions}',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: _panelDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final item in current.items) ...[
                      if (item != current.items.first)
                        const Divider(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.product.name} × ${item.quantity}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            'P${item.total}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.size} · ${item.sugar} sugar · ${item.ice} ice',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (item.addIns.isNotEmpty || item.addOns.isNotEmpty)
                        Text(
                          [...item.addIns, ...item.addOns].join(', '),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order total',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'P${current.total}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (current.status == 'Pending') ...[
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => _confirmCancellation(context, current),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel order'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFC62828),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmCancellation(
    BuildContext context,
    PlacedOrder current,
  ) async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text('This will mark the order as cancelled.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep order'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
            ),
            child: const Text('Cancel order'),
          ),
        ],
      ),
    );
    if (shouldCancel == true) OrdersStore.updateStatus(current.id, 'Cancelled');
  }
}

const _panelDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(12)),
  border: Border.fromBorderSide(BorderSide(color: Color(0xFFE7E7E7))),
);

Color _statusColor(String status) => switch (status) {
  'Pending' => AppColors.orange,
  'Preparing' => const Color(0xFFB76B00),
  'Completed' => const Color(0xFF2E7D32),
  _ => const Color(0xFFC62828),
};

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
