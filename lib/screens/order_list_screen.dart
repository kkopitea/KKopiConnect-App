import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/order_repository.dart';
import '../data/placed_order.dart';
import '../state/orders_store.dart';
import '../widgets/cloudinary_image.dart';
import '../widgets/curved_content_page.dart';
import '../widgets/main_bottom_navigation_bar.dart';
import 'categories_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({
    super.key,
    this.userId,
    this.orderRepository,
    this.onNavigateTab,
  });

  final String? userId;
  final OrderRepository? orderRepository;
  final ValueChanged<int>? onNavigateTab;

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final Set<String> _selectedOrderIds = {};
  bool _isSelectingOrders = false;
  bool _isDeletingOrders = false;
  late String? _activeUserId;
  late Stream<List<PlacedOrder>> _ordersStream;

  @override
  void initState() {
    super.initState();
    _updateOrdersStream();
  }

  @override
  void didUpdateWidget(covariant OrderListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.orderRepository != widget.orderRepository) {
      _updateOrdersStream();
    }
  }

  void _updateOrdersStream() {
    _activeUserId = widget.userId ?? FirebaseAuth.instance.currentUser?.uid;
    _ordersStream = _activeUserId == null
        ? Stream<List<PlacedOrder>>.empty()
        : (widget.orderRepository ?? FirestoreOrderRepository()).watchOrders(
            _activeUserId!,
          );
  }

  @override
  Widget build(BuildContext context) {
    return CurvedContentPage(
      title: 'MY ORDERS',
      body: StreamBuilder<List<PlacedOrder>>(
        stream: _ordersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            final errorCode = error is FirebaseException
                ? ' (${error.code})'
                : '';
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Could not load orders$errorCode.'),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => setState(_updateOrdersStream),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final orders = snapshot.data ?? const <PlacedOrder>[];

          if (_activeUserId == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 44,
                      color: AppColors.orange,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please sign in',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sign in to view your orders.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

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

          final orderIds = orders.map((order) => order.id).toSet();
          final deletableOrderIds = orders
              .where(_isDeletableOrder)
              .map((order) => order.id)
              .toSet();
          _selectedOrderIds.removeWhere(
            (id) => !orderIds.contains(id) || !deletableOrderIds.contains(id),
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Order history',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (_isSelectingOrders) ...[
                      TextButton(
                        onPressed: _isDeletingOrders
                            ? null
                            : () => setState(() {
                                _selectedOrderIds.clear();
                                _isSelectingOrders = false;
                              }),
                        child: const Text('Done'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed:
                            _selectedOrderIds.isEmpty || _isDeletingOrders
                            ? null
                            : () => _confirmDeleteOrders(
                                _activeUserId!,
                                _selectedOrderIds.toList(),
                              ),
                        icon: _isDeletingOrders
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.delete_outline_rounded),
                        label: Text('Delete (${_selectedOrderIds.length})'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ] else
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _isSelectingOrders = true;
                        }),
                        icon: const Icon(Icons.checklist_rounded),
                        label: const Text('Select'),
                      ),
                  ],
                ),
              ),
              if (_isSelectingOrders)
                const Padding(
                  padding: EdgeInsets.fromLTRB(14, 4, 14, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Only completed or cancelled orders can be deleted.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _OrderCard(
                    order: orders[index],
                    isSelecting: _isSelectingOrders,
                    isSelected: _selectedOrderIds.contains(orders[index].id),
                    onTap: () {
                      if (_isSelectingOrders) {
                        if (!_isDeletableOrder(orders[index])) return;
                        setState(() {
                          final orderId = orders[index].id;
                          if (!_selectedOrderIds.add(orderId)) {
                            _selectedOrderIds.remove(orderId);
                          }
                        });
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => OrderDetailsScreen(
                              order: orders[index],
                              onNavigateTab: widget.onNavigateTab,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isDeletableOrder(PlacedOrder order) {
    final status = order.status.toLowerCase();
    return status == 'completed' || status == 'cancelled';
  }

  Future<void> _confirmDeleteOrders(
    String userId,
    List<String> orderIds,
  ) async {
    final shouldHide = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          orderIds.length == 1
              ? 'Delete this order?'
              : 'Delete selected orders?',
        ),
        content: Text(
          orderIds.length == 1
              ? 'This permanently deletes the order from your history and the store records.'
              : 'This permanently deletes these ${orderIds.length} orders from your history and the store records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep orders'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldHide != true || !mounted) return;

    setState(() => _isDeletingOrders = true);
    try {
      await (widget.orderRepository ?? FirestoreOrderRepository()).deleteOrders(
        userId: userId,
        orderIds: orderIds,
      );
      if (!mounted) return;
      setState(() {
        _selectedOrderIds.clear();
        _isSelectingOrders = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            orderIds.length == 1
                ? 'Order permanently deleted.'
                : '${orderIds.length} orders permanently deleted.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete selected orders: $error')),
      );
    } finally {
      if (mounted) setState(() => _isDeletingOrders = false);
    }
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.isSelecting,
    required this.isSelected,
  });

  final PlacedOrder order;
  final VoidCallback onTap;
  final bool isSelecting;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final firstProduct = order.items.isEmpty ? null : order.items.first.product;
    final name = order.items.isEmpty
        ? 'Order items unavailable'
        : order.items.length == 1
        ? order.items.first.product.name
        : '${order.items.first.product.name} + ${order.items.length - 1} more';
    final statusColor = _statusColor(order.status);

    return Material(
      color: isSelected ? AppColors.orangeTint : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.orangeTint,
        highlightColor: AppColors.orangeTint,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (isSelecting) ...[
                Icon(
                  !_isDeletable
                      ? Icons.block_rounded
                      : isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: !_isDeletable
                      ? AppColors.inputBorder
                      : isSelected
                      ? AppColors.orange
                      : AppColors.iconMuted,
                ),
                const SizedBox(width: 10),
              ],
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
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatDate(order.createdAt)} · ${AppColors.pesoSymbol}${order.total}',
                      style: const TextStyle(
                        fontSize: 13,
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
                    fontSize: 12,
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

  bool get _isDeletable {
    final normalizedStatus = order.status.toLowerCase();
    return normalizedStatus == 'completed' || normalizedStatus == 'cancelled';
  }
}

class OrderDetailsScreen extends StatelessWidget {
  const OrderDetailsScreen({
    super.key,
    required this.order,
    this.onNavigateTab,
  });

  final PlacedOrder order;
  final ValueChanged<int>? onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final orderStream = user == null
        ? null
        : FirestoreOrderRepository().watchOrders(user.uid);

    return CurvedContentPage(
      title: 'Order Details',
      bottomNavigationBar: onNavigateTab == null
          ? null
          : MainBottomNavigationBar(
              selectedIndex: 3,
              onTap: (index) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                onNavigateTab!(index);
              },
            ),
      body: StreamBuilder<List<PlacedOrder>>(
        stream: orderStream,
        builder: (context, orderSnapshot) =>
            ValueListenableBuilder<List<PlacedOrder>>(
              valueListenable: OrdersStore.orders,
              builder: (context, orders, _) {
                final remoteMatches =
                    (orderSnapshot.data ?? const <PlacedOrder>[]).where(
                      (item) => item.id == order.id,
                    );
                final localMatches = orders.where(
                  (item) => item.id == order.id,
                );
                final current = remoteMatches.isNotEmpty
                    ? remoteMatches.first
                    : localMatches.isNotEmpty
                    ? localMatches.first
                    : order;
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
                              style: const TextStyle(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _OrderTrackingCard(
                      status: current.status,
                      createdAt: current.createdAt,
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
                              fontSize: 17,
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${AppColors.pesoSymbol}${item.total}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.size} · ${item.sugar} sugar',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                            if (item.addIns.isNotEmpty ||
                                item.addOns.isNotEmpty)
                              Text(
                                [...item.addIns, ...item.addOns].join(', '),
                                style: const TextStyle(
                                  fontSize: 13,
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
                                '${AppColors.pesoSymbol}${current.total}',
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
    if (shouldCancel != true) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirestoreOrderRepository().updateOrderStatus(
          userId: user.uid,
          orderId: current.id,
          status: 'Cancelled',
        );
      }
      OrdersStore.updateStatus(current.id, 'Cancelled');
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to cancel order: $error')));
    }
  }
}

class _OrderTrackingCard extends StatelessWidget {
  const _OrderTrackingCard({required this.status, required this.createdAt});

  final String status;
  final DateTime createdAt;

  static const _steps = ['Order placed', 'Preparing', 'Completed'];

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();
    final isCancelled = normalizedStatus == 'cancelled';
    final activeStep = switch (normalizedStatus) {
      'pending' => 0,
      'preparing' => 1,
      'completed' => 2,
      _ => -1,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order tracking',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          if (isCancelled) ...[
            const Row(
              children: [
                Icon(Icons.cancel_rounded, color: Color(0xFFC62828), size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This order was cancelled.',
                    style: TextStyle(
                      color: Color(0xFFC62828),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          for (var index = 0; index < _steps.length; index++) ...[
            _OrderTrackingStep(
              title: _steps[index],
              description: switch (index) {
                0 => 'Received ${_formatDate(createdAt)}',
                1 => 'The branch is preparing your items.',
                _ => 'Your order has been completed.',
              },
              isComplete:
                  !isCancelled &&
                  (index < activeStep || normalizedStatus == 'completed'),
              isCurrent:
                  !isCancelled &&
                  index == activeStep &&
                  normalizedStatus != 'completed',
            ),
            if (index < _steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 11),
                child: Container(
                  width: 2,
                  height: 18,
                  color: !isCancelled && index < activeStep
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE0E0E0),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _OrderTrackingStep extends StatelessWidget {
  const _OrderTrackingStep({
    required this.title,
    required this.description,
    required this.isComplete,
    required this.isCurrent,
  });

  final String title;
  final String description;
  final bool isComplete;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isComplete
        ? const Color(0xFF2E7D32)
        : isCurrent
        ? AppColors.orange
        : AppColors.textMuted;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isComplete
              ? Icons.check_circle_rounded
              : isCurrent
              ? Icons.radio_button_checked_rounded
              : Icons.radio_button_unchecked_rounded,
          color: color,
          size: 24,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isComplete || isCurrent
                        ? Colors.black
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

const _panelDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(12)),
  border: Border(
    top: BorderSide(color: Colors.white),
    right: BorderSide(color: Colors.white),
    bottom: BorderSide(color: Colors.white),
    left: BorderSide(color: Colors.white),
  ),
);

Color _statusColor(String status) => switch (status.toLowerCase()) {
  'pending' => AppColors.orange,
  'preparing' => const Color(0xFFB76B00),
  'completed' => const Color(0xFF2E7D32),
  'cancelled' => const Color(0xFFC62828),
  _ => AppColors.textMuted,
};

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}
