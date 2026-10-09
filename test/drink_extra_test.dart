import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kkopiconnect_app/data/app_notification.dart';
import 'package:kkopiconnect_app/data/drink_extra.dart';
import 'package:kkopiconnect_app/data/menu_catalog.dart';
import 'package:kkopiconnect_app/data/order_draft.dart';
import 'package:kkopiconnect_app/data/payment_method.dart';
import 'package:kkopiconnect_app/data/placed_order.dart';

void main() {
  test('drink extras parse configurable fields', () {
    final option = DrinkExtra.fromMap('pearls', {
      'name': 'Pearls',
      'price': 22.5,
      'isAvailable': true,
      'sortOrder': 3,
    });

    expect(option.id, 'pearls');
    expect(option.name, 'Pearls');
    expect(option.price, 22);
    expect(option.isAvailable, isTrue);
    expect(option.sortOrder, 3);
  });

  test('configured drink extra prices round-trip and are used in totals', () {
    final draft = OrderDraft(
      product: menuProducts.first,
      addIns: const {'Custom syrup'},
      addOns: const {'Oat foam'},
      addInUnitPrices: const {'Custom syrup': 7},
      addOnUnitPrices: const {'Oat foam': 35},
    );

    final restored = OrderDraft.fromMap(draft.toMap());

    expect(restored.addInUnitPrices['Custom syrup'], 7);
    expect(restored.addOnUnitPrices['Oat foam'], 35);
    expect(restored.total, draft.product.price + 42);
  });

  test('orders parse Firestore server timestamps', () {
    final createdAt = DateTime.utc(2026, 10, 9, 6, 30);
    final order = PlacedOrder.fromMap({
      'id': 'KK123',
      'items': const [],
      'fulfillment': 'Pickup',
      'paymentMethod': 'Gcash',
      'instructions': '',
      'status': 'Pending',
      'createdAt': Timestamp.fromDate(createdAt),
    });

    expect(order.createdAt.isAtSameMomentAs(createdAt), isTrue);
  });

  test('admin-managed category, notification, and payment schemas parse', () {
    final category = MenuCategory.fromFirestore('fruit_tea', {
      'name': 'Fruit Tea',
      'iconKey': 'fruitTea',
      'sortOrder': 4,
    });
    final notification = AppNotification.fromFirestore('new-menu', {
      'title': 'New Menu',
      'message': 'Try our new drink.',
      'type': 'System',
      'isActive': true,
      'sortOrder': 1,
      'iconKey': 'coffee',
    });
    final paymentMethod = PaymentMethod.fromFirestore('gcash', {
      'name': 'GCash',
      'isActive': true,
      'sortOrder': 1,
      'instructions': 'Pay with GCash.',
    });

    expect(category.name, 'Fruit Tea');
    expect(category.sortOrder, 4);
    expect(notification?.type, 'System');
    expect(notification?.isActive, isTrue);
    expect(paymentMethod?.name, 'GCash');
    expect(paymentMethod?.instructions, 'Pay with GCash.');
  });
}
