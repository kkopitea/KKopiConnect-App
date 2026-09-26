import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kkopiconnect_app/data/menu_catalog.dart';
import 'package:kkopiconnect_app/data/order_draft.dart';
import 'package:kkopiconnect_app/data/placed_order.dart';
import 'package:kkopiconnect_app/firebase_options.dart';
import 'package:kkopiconnect_app/screens/cart_screen.dart';
import 'package:kkopiconnect_app/state/cart_store.dart';
import 'package:kkopiconnect_app/state/orders_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  setUp(() {
    CartStore.clear();
    OrdersStore.orders.value = <PlacedOrder>[];
  });

  test('order line data round-trips through a Firestore-compatible map', () {
    final draft = OrderDraft(
      product: menuProducts.first,
      quantity: 2,
      size: 'Large',
      sizePrice: 100,
      sugar: '25%',
      ice: '50%',
      addIns: const {'Pearls'},
      addOns: const {'Coffee Jelly'},
    );

    final restored = OrderDraft.fromMap(draft.toMap());

    expect(restored.product.id, draft.product.id);
    expect(restored.quantity, 2);
    expect(restored.size, 'Large');
    expect(restored.addIns, contains('Pearls'));
    expect(restored.addOns, contains('Coffee Jelly'));
    expect(restored.total, draft.total);
  });

  testWidgets(
    'cart proceeds through checkout and creates visible order history',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      CartStore.add(OrderDraft(product: menuProducts.first));
      await tester.pumpWidget(const MaterialApp(home: CartScreen()));

      expect(find.text('Iced Americano Caramel'), findsOneWidget);
      await tester.tap(find.text('Proceed'));
      await tester.pumpAndSettle();
      expect(find.text('Order type & Payment method'), findsOneWidget);

      final placeOrderButton = find.widgetWithText(FilledButton, 'Place Order');
      await tester.ensureVisible(placeOrderButton);
      await tester.tap(placeOrderButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Order #KK'), findsOneWidget);
      expect(CartStore.items.value, isEmpty);
      expect(OrdersStore.orders.value, hasLength(1));

      await tester.tap(find.text('View my orders'));
      await tester.pumpAndSettle();
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.textContaining('KK'), findsOneWidget);
    },
  );
}
