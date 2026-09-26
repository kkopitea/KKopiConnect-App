import 'package:flutter/foundation.dart';

class FavoritesStore {
  FavoritesStore._();

  static final ValueNotifier<Set<String>> productIds = ValueNotifier({});

  static bool contains(String productId) => productIds.value.contains(productId);

  static void toggle(String productId) {
    final updated = Set<String>.of(productIds.value);
    if (!updated.add(productId)) updated.remove(productId);
    productIds.value = Set.unmodifiable(updated);
  }

  static void remove(String productId) {
    final updated = Set<String>.of(productIds.value)..remove(productId);
    productIds.value = Set.unmodifiable(updated);
  }
}
