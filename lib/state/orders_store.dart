import 'package:flutter/foundation.dart';

import '../data/order_draft.dart';
import '../data/placed_order.dart';

class OrdersStore {
  OrdersStore._();

  static final ValueNotifier<List<PlacedOrder>> orders = ValueNotifier([]);

  static void updateStatus(String orderId, String status) {
    orders.value = List.unmodifiable(
      orders.value
          .map(
            (order) =>
                order.id == orderId ? order.copyWith(status: status) : order,
          )
          .toList(),
    );
  }

  static PlacedOrder createOrder({
    required List<OrderDraft> items,
    required String fulfillment,
    required String paymentMethod,
    required String instructions,
  }) {
    final now = DateTime.now();
    final id = 'KK${now.millisecondsSinceEpoch}';
    final order = PlacedOrder(
      id: id,
      items: List.unmodifiable(items),
      fulfillment: fulfillment,
      paymentMethod: paymentMethod,
      instructions: instructions,
      status: 'Pending',
      createdAt: now,
    );
    orders.value = List.unmodifiable([order, ...orders.value]);
    return order;
  }

  static void removeOrder(String orderId) => orders.value = List.unmodifiable(
    orders.value.where((order) => order.id != orderId),
  );
}
