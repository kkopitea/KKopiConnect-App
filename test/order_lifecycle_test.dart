import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kkopiconnect_app/app_colors.dart';
import 'package:kkopiconnect_app/data/menu_catalog.dart';
import 'package:kkopiconnect_app/data/order_draft.dart';
import 'package:kkopiconnect_app/data/order_number.dart';
import 'package:kkopiconnect_app/data/order_repository.dart';
import 'package:kkopiconnect_app/data/payment_method.dart';
import 'package:kkopiconnect_app/data/payment_method_repository.dart';
import 'package:kkopiconnect_app/data/placed_order.dart';
import 'package:kkopiconnect_app/screens/cart_screen.dart';
import 'package:kkopiconnect_app/screens/order_list_screen.dart';
import 'package:kkopiconnect_app/screens/order_type_screen.dart';
import 'package:kkopiconnect_app/state/cart_store.dart';
import 'package:kkopiconnect_app/state/orders_store.dart';
import 'package:kkopiconnect_app/widgets/main_bottom_navigation_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      ice: '25%',
      addIns: const {'Pearls'},
      addOns: const {'Coffee Jelly'},
    );

    final restored = OrderDraft.fromMap(draft.toMap());

    expect(restored.product.id, draft.product.id);
    expect(restored.quantity, 2);
    expect(restored.size, 'Large');
    expect(restored.addIns, contains('Pearls'));
    expect(restored.addOns, contains('Coffee Jelly'));
    expect(restored.ice, '25%');
    expect(restored.total, draft.total);
  });

  testWidgets('checkout keeps the white bottom navigation available', (
    tester,
  ) async {
    var selectedTab = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: OrderTypeScreen(
          drafts: [OrderDraft(product: menuProducts.first)],
          customerId: 'guest-test-user',
          initialCustomerName: 'Test Guest',
          updateCustomerName: (_) async {},
          paymentMethodSource: _FakePaymentMethodSource(),
          orderRepository: _FakeOrderRepository(),
          onNavigateTab: (index) => selectedTab = index,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final navigation = tester.widget<MainBottomNavigationBar>(
      find.byType(MainBottomNavigationBar),
    );
    expect(navigation.selectedIndex, 2);
    _expectWhiteSystemNavigationBar(tester);

    await tester.tap(find.text('Orders'));
    expect(selectedTab, 3);
  });

  testWidgets(
    'cart proceeds through checkout and creates visible order history',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final orderRepository = _FakeOrderRepository();

      CartStore.add(OrderDraft(product: menuProducts.first));
      await tester.pumpWidget(
        MaterialApp(
          home: CartScreen(
            checkoutBuilder: (drafts) => OrderTypeScreen(
              drafts: drafts,
              customerId: 'guest-test-user',
              initialCustomerName: 'Test Guest',
              updateCustomerName: (_) async {},
              paymentMethodSource: _FakePaymentMethodSource(),
              orderRepository: orderRepository,
              orderListBuilder: (_) => OrderListScreen(
                userId: 'guest-test-user',
                orderRepository: orderRepository,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Iced Americano Caramel'), findsOneWidget);
      _expectWhiteSystemNavigationBar(tester);
      await tester.tap(find.text('Proceed'));
      await tester.pumpAndSettle();
      expect(find.text('Order type & payment method'), findsOneWidget);
      _expectWhiteSystemNavigationBar(tester);

      final placeOrderButton = find.widgetWithText(FilledButton, 'Place Order');
      await tester.drag(find.byType(ListView).last, const Offset(0, -400));
      await tester.pumpAndSettle();
      await tester.tap(placeOrderButton);
      await tester.pumpAndSettle();
      expect(find.textContaining('Order #KK001'), findsOneWidget);
      _expectWhiteSystemNavigationBar(tester);
      expect(CartStore.items.value, isEmpty);
      expect(OrdersStore.orders.value, hasLength(1));
      expect(orderRepository.orders, hasLength(1));
      expect(orderRepository.orders.single.id, '#KK001');

      orderRepository.orders[0] = orderRepository.orders[0].copyWith(
        status: 'Completed',
      );
      await tester.tap(find.text('View my orders'));
      await tester.pumpAndSettle();
      expect(find.text('MY ORDERS'), findsOneWidget);
      _expectWhiteSystemNavigationBar(tester);
      expect(find.textContaining('KK'), findsOneWidget);

      await tester.tap(find.text('Select'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('#KK001'));
      await tester.pumpAndSettle();
      expect(find.text('Delete (1)'), findsOneWidget);

      await tester.tap(find.text('Delete (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this order?'), findsOneWidget);
      expect(find.textContaining('permanently deletes'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(find.text('No orders yet'), findsOneWidget);
      expect(orderRepository.orders, isEmpty);
    },
  );

  testWidgets('pending orders cannot be selected for deletion', (tester) async {
    final repository = _FakeOrderRepository()
      ..orders.add(
        PlacedOrder(
          id: '#KK009',
          items: [OrderDraft(product: menuProducts.first)],
          fulfillment: 'Pickup',
          paymentMethod: 'Pay At The Counter',
          instructions: '',
          status: 'Pending',
          createdAt: DateTime.utc(2025),
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: OrderListScreen(
          userId: 'guest-test-user',
          orderRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#KK009'));
    await tester.pumpAndSettle();

    expect(find.text('Delete (0)'), findsOneWidget);
    expect(
      find.textContaining('Only completed or cancelled orders can be deleted.'),
      findsOneWidget,
    );
    expect(repository.orders, hasLength(1));
  });

  testWidgets('selected order card uses the soft orange highlight', (
    tester,
  ) async {
    final repository = _FakeOrderRepository()
      ..orders.add(
        PlacedOrder(
          id: '#KK010',
          items: [OrderDraft(product: menuProducts.first)],
          fulfillment: 'Pickup',
          paymentMethod: 'Pay At The Counter',
          instructions: '',
          status: 'Completed',
          createdAt: DateTime.utc(2025),
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: OrderListScreen(
          userId: 'guest-test-user',
          orderRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('#KK010'));
    await tester.pumpAndSettle();

    final card = find
        .ancestor(of: find.text('#KK010'), matching: find.byType(Material))
        .first;
    expect(tester.widget<Material>(card).color, AppColors.orangeTint);
  });

  testWidgets('selecting orders keeps the existing history stream', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeOrderRepository()
      ..orders.addAll(
        List.generate(
          20,
          (index) => PlacedOrder(
            id: '#KK${(index + 1).toString().padLeft(3, '0')}',
            items: [OrderDraft(product: menuProducts.first)],
            fulfillment: 'Pickup',
            paymentMethod: 'Pay At The Counter',
            instructions: '',
            status: 'Completed',
            createdAt: DateTime.utc(2025),
          ),
        ),
      );

    await tester.pumpWidget(
      MaterialApp(
        home: OrderListScreen(
          userId: 'guest-test-user',
          orderRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repository.watchCalls, 1);

    final listFinder = find.byType(ListView).last;
    await tester.drag(listFinder, const Offset(0, -500));
    await tester.pumpAndSettle();
    final scrollableFinder = find.descendant(
      of: listFinder,
      matching: find.byType(Scrollable),
    );
    final scrollOffset = tester
        .state<ScrollableState>(scrollableFinder)
        .position
        .pixels;
    expect(scrollOffset, greaterThan(0));

    await tester.tap(find.text('Select'));
    await tester.pumpAndSettle();

    expect(repository.watchCalls, 1);
    expect(
      tester.state<ScrollableState>(scrollableFinder).position.pixels,
      scrollOffset,
    );
  });

  testWidgets('order history exposes Firestore errors and can retry', (
    tester,
  ) async {
    final repository = _FakeOrderRepository()..failWatch = true;

    await tester.pumpWidget(
      MaterialApp(
        home: OrderListScreen(
          userId: 'guest-test-user',
          orderRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Could not load orders (permission-denied).'),
      findsOneWidget,
    );
    expect(repository.watchCalls, 1);

    repository.failWatch = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(repository.watchCalls, 2);
    expect(find.text('No orders yet'), findsOneWidget);
  });
}

class _FakePaymentMethodSource implements PaymentMethodSource {
  @override
  Stream<List<PaymentMethod>> watchActive() =>
      Stream.value(defaultPaymentMethods);

  @override
  Future<void> save(PaymentMethod method) async {}
}

class _FakeOrderRepository implements OrderRepository {
  final List<PlacedOrder> orders = [];
  final StreamController<List<PlacedOrder>> _ordersController =
      StreamController<List<PlacedOrder>>.broadcast(sync: true);
  int watchCalls = 0;
  bool failWatch = false;

  @override
  Future<PlacedOrder> saveOrder(
    String userId,
    PlacedOrder order, {
    required String customerName,
  }) async {
    final savedOrder = order.copyWith(id: formatOrderNumber(orders.length + 1));
    orders.add(savedOrder);
    _emitOrders();
    return savedOrder;
  }

  @override
  Stream<List<PlacedOrder>> watchOrders(String userId) {
    watchCalls++;
    if (failWatch) {
      return Stream.error(
        FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
    }
    return Stream<List<PlacedOrder>>.multi((controller) {
      final subscription = _ordersController.stream.listen(
        controller.add,
        onError: controller.addError,
      );
      controller.add(_visibleOrders);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> deleteOrders({
    required String userId,
    required List<String> orderIds,
  }) async {
    orders.removeWhere((order) => orderIds.contains(order.id));
    _emitOrders();
  }

  List<PlacedOrder> get _visibleOrders => List.unmodifiable(orders);

  void _emitOrders() => _ordersController.add(_visibleOrders);

  @override
  Future<void> updateOrderStatus({
    required String userId,
    required String orderId,
    required String status,
  }) async {}
}

void _expectWhiteSystemNavigationBar(WidgetTester tester) {
  final style = tester
      .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      )
      .first
      .value;
  expect(style.systemNavigationBarColor, Colors.white);
  expect(style.systemNavigationBarIconBrightness, Brightness.dark);
}
