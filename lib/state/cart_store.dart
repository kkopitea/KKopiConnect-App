import 'package:flutter/foundation.dart';

import '../data/order_draft.dart';

class CartStore {
  CartStore._();

  static final ValueNotifier<List<OrderDraft>> items = ValueNotifier([]);

  static int get total =>
      items.value.fold<int>(0, (sum, item) => sum + item.total);

  static void add(OrderDraft draft) {
    items.value = List.unmodifiable([...items.value, draft]);
  }

  static void updateQuantity(int index, int quantity) {
    if (index < 0 || index >= items.value.length || quantity < 1) return;
    final updated = List<OrderDraft>.of(items.value);
    updated[index] = updated[index].copyWith(quantity: quantity);
    items.value = List.unmodifiable(updated);
  }

  static void removeAt(int index) {
    if (index < 0 || index >= items.value.length) return;
    final updated = List<OrderDraft>.of(items.value)..removeAt(index);
    items.value = List.unmodifiable(updated);
  }

  static void removeItems(List<OrderDraft> itemsToRemove) {
    final remainingToRemove = List<OrderDraft>.of(itemsToRemove);
    final remaining = <OrderDraft>[];
    for (final item in items.value) {
      final matchingIndex = remainingToRemove.indexWhere(
        (candidate) => identical(candidate, item),
      );
      if (matchingIndex >= 0) {
        remainingToRemove.removeAt(matchingIndex);
      } else {
        remaining.add(item);
      }
    }
    items.value = List.unmodifiable(remaining);
  }

  static void clear() => items.value = const [];
}
