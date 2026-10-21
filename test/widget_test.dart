// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kkopiconnect_app/main.dart';
import 'package:kkopiconnect_app/screens/cart_screen.dart';
import 'package:kkopiconnect_app/screens/chatbot_screen.dart';
import 'package:kkopiconnect_app/screens/customize_drink_screen.dart';
import 'package:kkopiconnect_app/screens/home_screen.dart';
import 'package:kkopiconnect_app/screens/login_screen_redesign.dart';
import 'package:kkopiconnect_app/screens/order_type_screen.dart';
import 'package:kkopiconnect_app/screens/order_confirmation_screen.dart';
import 'package:kkopiconnect_app/screens/welcome_screen.dart';
import 'package:kkopiconnect_app/screens/product_detail_screen.dart';
import 'package:kkopiconnect_app/data/menu_catalog.dart';
import 'package:kkopiconnect_app/data/order_draft.dart';
import 'package:kkopiconnect_app/data/payment_method.dart';
import 'package:kkopiconnect_app/data/payment_method_repository.dart';
import 'package:kkopiconnect_app/data/placed_order.dart';
import 'package:kkopiconnect_app/data/product_rating_repository.dart';
import 'package:kkopiconnect_app/services/chatbot_service.dart';
import 'package:kkopiconnect_app/services/chatbot_history_store.dart';
import 'package:kkopiconnect_app/services/guest_name_prompt.dart';
import 'package:kkopiconnect_app/state/cart_store.dart';
import 'package:kkopiconnect_app/state/favorites_store.dart';
import 'package:kkopiconnect_app/state/product_ratings_store.dart';
import 'package:kkopiconnect_app/widgets/cloudinary_image.dart';
import 'package:kkopiconnect_app/widgets/product_rating_control.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'product ratings are independent of favorites and rank best sellers',
    () {
      final products = menuProducts.take(3).toList();
      FavoritesStore.productIds.value = {products.first.id};
      ProductRatingsStore.summaries.value = {
        products[0].id: const ProductRatingSummary(
          average: 4.2,
          count: 5,
          total: 21,
        ),
        products[1].id: const ProductRatingSummary(
          average: 4.8,
          count: 3,
          total: 14,
        ),
        products[2].id: const ProductRatingSummary(
          average: 3.5,
          count: 2,
          total: 7,
        ),
      };

      expect(ProductRatingsStore.bestRatedProducts(products), [
        products[1],
        products[0],
        products[2],
      ]);
      expect(FavoritesStore.contains(products.first.id), isTrue);
      expect(
        ProductRatingSummary.fromData({
          'ratingAverage': 5,
          'ratingCount': 1,
          'ratingTotal': 5,
        }).average,
        5,
      );

      ProductRatingsStore.summaries.value = const {};
      FavoritesStore.productIds.value = const {};
    },
  );

  testWidgets('star rating can be set and changed separately', (tester) async {
    int? selectedRating;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductRatingControl(
            summary: const ProductRatingSummary(
              average: 4.5,
              count: 2,
              total: 9,
            ),
            userRating: null,
            onRate: (rating) => selectedRating = rating,
          ),
        ),
      ),
    );

    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('(2 ratings)'), findsOneWidget);
    expect(find.text('Rate this drink'), findsOneWidget);
    await tester.tap(find.byTooltip('Rate 4 out of 5 stars'));
    expect(selectedRating, 4);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductRatingControl(
            summary: const ProductRatingSummary(
              average: 4.3,
              count: 3,
              total: 13,
            ),
            userRating: 4,
            onRate: (rating) => selectedRating = rating,
          ),
        ),
      ),
    );
    expect(find.text('Your rating: 4/5'), findsOneWidget);
    await tester.tap(find.byTooltip('Change rating to 2 out of 5 stars'));
    expect(selectedRating, 2);
  });

  testWidgets('login screen offers guest access without registration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Continue as guest'), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
      Colors.white,
    );
    final systemUiStyle = tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        )
        .first
        .value;
    expect(systemUiStyle.systemNavigationBarColor, Colors.white);
    expect(systemUiStyle.systemNavigationBarIconBrightness, Brightness.dark);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Positioned &&
            widget.bottom == 0 &&
            widget.child is ColoredBox &&
            (widget.child as ColoredBox).color == Colors.white,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('guest name prompt requires a name before continuing', (
    tester,
  ) async {
    Future<String?>? guestName;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => guestName = showGuestNamePrompt(context),
                child: const Text('Start guest session'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Start guest session'));
    await tester.pumpAndSettle();
    expect(find.text('What name should we use?'), findsOneWidget);
    expect(find.text('KKOPI.TEA'), findsOneWidget);
    expect(find.text('COFFEE  •  MILKTEA  •  GOOD VIBES'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter your name.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Ari Santos');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(await guestName, 'Ari Santos');
  });

  testWidgets('welcome slides appear once and mark completion at get started', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome!'), findsOneWidget);
    expect(find.text('Get started'), findsNothing);
    await tester.tap(find.text('skip'));
    await tester.pumpAndSettle();
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getBool('hasSeenWelcomeSlides'), isTrue);
  });

  test('removing ordered cart items leaves unselected items in the cart', () {
    CartStore.clear();
    final selectedItem = OrderDraft(product: menuProducts[0]);
    final unselectedItem = OrderDraft(product: menuProducts[1]);
    CartStore.add(selectedItem);
    CartStore.add(unselectedItem);

    CartStore.removeItems([selectedItem]);

    expect(CartStore.items.value, [same(unselectedItem)]);
    CartStore.clear();
  });

  testWidgets('order confirmation uses a white system navigation bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderConfirmationScreen(
          order: PlacedOrder(
            id: 'KK123',
            items: const [],
            fulfillment: 'Pickup',
            paymentMethod: 'Pay At The Counter',
            instructions: '',
            status: 'Pending',
            createdAt: DateTime(2026),
          ),
        ),
      ),
    );

    _expectWhiteSystemNavigationBar(tester);
  });

  testWidgets('app starts on the splash screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KkopiTeaApp());

    expect(find.text('KKOPI.TEA'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('home rounded content panel fits a narrow screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: HomeScreen(onSeeAllCategories: () {})),
    );
    await tester.pumpAndSettle();

    expect(find.text('Best Selling'), findsOneWidget);
    expect(find.text('All Products'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat assistant answers menu price questions', (tester) async {
    final chatbotService = _FakeChatbotReplyService();
    await tester.pumpWidget(
      MaterialApp(home: ChatbotScreen(chatbotService: chatbotService)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Mango Fruit Tea price');
    await tester.tap(find.byTooltip('Send message'));
    await _waitForChatPersistence(tester);
    await tester.pumpAndSettle();
    expect(
      _findChatMessage('Here is the current menu information.'),
      findsOneWidget,
    );
    expect(chatbotService.lastQuestion, 'Mango Fruit Tea price');
    expect(
      chatbotService.lastProducts.any(
        (product) => product.name == 'Mango Fruit Tea',
      ),
      isTrue,
    );
  });

  testWidgets('quick prompt appears as a user message in the chat', (
    tester,
  ) async {
    final chatbotService = _FakeChatbotReplyService();
    await tester.pumpWidget(
      MaterialApp(home: ChatbotScreen(chatbotService: chatbotService)),
    );
    await tester.pumpAndSettle();

    const prompt = 'Recommend a drink for me';
    await tester.tap(find.text(prompt));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pumpAndSettle();

    expect(find.text(prompt), findsOneWidget);
    expect(_findChatMessage(prompt), findsNWidgets(2));
    expect(
      _findChatMessage('Here is the current menu information.'),
      findsOneWidget,
    );
    expect(chatbotService.lastQuestion, prompt);
  });

  testWidgets('chat history remains after leaving and reopening the screen', (
    tester,
  ) async {
    await ChatbotHistoryStore().save(const [
      ChatbotHistoryMessage(text: 'What should I try?', fromUser: true),
      ChatbotHistoryMessage(
        text: 'Try Mango Fruit Tea.',
        fromUser: false,
        productIds: ['mango-fruit-tea'],
      ),
    ]);
    expect(await ChatbotHistoryStore().load(), hasLength(2));
    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotScreen(chatbotService: _FakeChatbotReplyService()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pumpAndSettle();
    expect(_findChatMessage('What should I try?'), findsOneWidget);
    expect(_findChatMessage('Try Mango Fruit Tea.'), findsOneWidget);
    expect(find.byTooltip('View and order Mango Fruit Tea'), findsOneWidget);
  });

  testWidgets('drink recommendations show no more than two product cards', (
    tester,
  ) async {
    final recommendations = menuProducts.take(3).toList();
    final chatbotService = _FakeChatbotReplyService(
      response: recommendations.map((product) => product.name).join(', '),
    );
    await tester.pumpWidget(
      MaterialApp(home: ChatbotScreen(chatbotService: chatbotService)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recommend a drink for me'));
    await tester.pumpAndSettle();

    expect(
      find.byTooltip('View and order ${recommendations[0].name}'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('View and order ${recommendations[1].name}'),
      findsOneWidget,
    );
    expect(
      find.byTooltip('View and order ${recommendations[2].name}'),
      findsNothing,
    );
  });

  testWidgets('best seller replies show product details and open the product', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotScreen(chatbotService: _FakeChatbotReplyService()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show best sellers'));
    await tester.pumpAndSettle();

    final product = menuProducts.firstWhere((item) => item.isBestSeller);
    expect(find.text(product.name), findsWidgets);
    expect(find.text(product.description), findsOneWidget);
    expect(find.byTooltip('View and order ${product.name}'), findsOneWidget);
    expect(find.byType(CloudinaryImage), findsWidgets);

    await tester.tap(find.byTooltip('View and order ${product.name}'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailScreen), findsOneWidget);
  });

  testWidgets('fruit tea prompt shows matching product cards', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotScreen(chatbotService: _FakeChatbotReplyService()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('What fruit tea do you have?'));
    await tester.pumpAndSettle();

    final fruitTea = menuProducts.firstWhere(
      (product) => product.categoryIds.contains('fruit_tea'),
    );
    expect(find.text(fruitTea.name), findsOneWidget);
    expect(find.text(fruitTea.description), findsOneWidget);
    expect(find.byTooltip('View and order ${fruitTea.name}'), findsOneWidget);
  });

  testWidgets('assistant formats bold text and markdown lists', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotScreen(
          chatbotService: _FakeChatbotReplyService(
            response: '**Popular picks**\n- **Mango Fruit Tea** is refreshing.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recommend a drink for me'));
    await tester.pumpAndSettle();

    final reply = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere(
          (widget) => widget.text.toPlainText().contains('Popular picks'),
        );
    expect(_hasBoldText(reply.text, 'Popular picks'), isTrue);
    expect(find.textContaining('**'), findsNothing);
    expect(reply.text.toPlainText(), contains('•  '));
  });

  testWidgets('assistant italicizes single-asterisk text at readable size', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotScreen(
          chatbotService: _FakeChatbotReplyService(response: '*16 oz:* P50'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Recommend a drink for me'));
    await tester.pumpAndSettle();

    final reply = tester
        .widgetList<RichText>(find.byType(RichText))
        .firstWhere((widget) => widget.text.toPlainText().contains('16 oz:'));
    expect(reply.text.toPlainText(), '16 oz: P50');
    expect(_hasItalicText(reply.text, '16 oz:'), isTrue);
    expect(reply.text.style?.fontSize, 16);
  });

  testWidgets('missing Groq Worker URL shows setup instructions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotScreen(chatbotService: _FailingChatbotReplyService()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Tell me about your store');
    await tester.tap(find.byTooltip('Send message'));
    await _waitForChatPersistence(tester);
    await tester.pumpAndSettle();

    expect(
      _findChatMessage(
        'Set GROQ_WORKER_URL when building the app to enable the assistant.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('unexpected chatbot errors are visible in debug builds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChatbotScreen(
          chatbotService: _UnexpectedFailingChatbotReplyService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Recommend a drink for me');
    await tester.tap(find.byTooltip('Send message'));
    await _waitForChatPersistence(tester);
    await tester.pumpAndSettle();

    expect(_findChatMessage('test failure'), findsOneWidget);
  });

  testWidgets('product actions stay pinned at the bottom on a small screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: ProductDetailScreen(product: menuProducts.first)),
    );
    await tester.pumpAndSettle();

    final customize = find.widgetWithText(OutlinedButton, 'Customize');
    final addToCart = find.widgetWithText(FilledButton, 'Add to cart');
    expect(customize, findsOneWidget);
    expect(addToCart, findsOneWidget);
    expect(find.text('16oz'), findsOneWidget);
    expect(find.text('22oz'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    expect(find.text('(0 ratings)'), findsOneWidget);
    expect(find.byTooltip('Rate 1 out of 5 stars'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(
      find.ancestor(of: addToCart, matching: find.byType(Scrollable)),
      findsNothing,
    );
    for (final control in [find.text('Sizes'), find.text('Quantity')]) {
      expect(
        find.ancestor(of: control, matching: find.byType(Scrollable)),
        findsNothing,
      );
    }
    expect(
      tester.getRect(customize).top,
      lessThan(tester.getRect(addToCart).top),
    );
    expect(tester.getRect(addToCart).bottom, greaterThan(720));
    expect(tester.takeException(), isNull);
  });

  testWidgets('drink customization no longer offers add ins or add-ons', (
    WidgetTester tester,
  ) async {
    final product = menuProducts.first;
    CartStore.clear();

    await tester.pumpWidget(
      MaterialApp(
        home: CustomizeDrinkScreen(
          draft: OrderDraft(
            product: product,
            size: '16oz',
            sizePrice: product.price,
            addIns: const {'Pearls'},
            addOns: const {'Coffee Jelly'},
            addInUnitPrices: const {'Pearls': 20},
            addOnUnitPrices: const {'Coffee Jelly': 30},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    _expectWhiteSystemNavigationBar(tester);
    expect(find.text('2. Add ins / your liking'), findsNothing);
    expect(find.text('3. Add-ons'), findsNothing);

    await tester.tap(find.textContaining('Add to cart'));
    await tester.pumpAndSettle();
    expect(CartStore.items.value.single.addIns, isEmpty);
    expect(CartStore.items.value.single.addOns, isEmpty);
    CartStore.clear();
  });

  testWidgets('curved cart page keeps empty-state text in view', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    CartStore.clear();

    await tester.pumpWidget(const MaterialApp(home: CartScreen()));
    await tester.pumpAndSettle();

    expect(find.text('MY CART'), findsOneWidget);
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cart selection controls which items can proceed to checkout', (
    WidgetTester tester,
  ) async {
    CartStore.clear();
    CartStore.add(OrderDraft(product: menuProducts[0]));
    CartStore.add(OrderDraft(product: menuProducts[1]));
    await tester.pumpWidget(const MaterialApp(home: CartScreen()));
    await tester.pumpAndSettle();

    final proceedButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Proceed'),
    );
    expect(proceedButton.onPressed, isNotNull);
    expect(find.text('Subtotal (2 items)'), findsOneWidget);

    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Subtotal (1 item)'), findsOneWidget);
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pumpAndSettle();
    final disabledProceedButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Proceed'),
    );
    expect(disabledProceedButton.onPressed, isNull);
    expect(CartStore.items.value, hasLength(2));
  });

  testWidgets('order type page has no duplicate bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrderTypeScreen(
          drafts: [OrderDraft(product: menuProducts.first)],
          initialCustomerName: 'Test Guest',
          paymentMethodSource: _TestPaymentMethodSource(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Order type & payment method'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _TestPaymentMethodSource implements PaymentMethodSource {
  @override
  Stream<List<PaymentMethod>> watchActive() =>
      Stream.value(defaultPaymentMethods);

  @override
  Future<void> save(PaymentMethod method) async {}
}

class _FakeChatbotReplyService implements ChatbotReplyService {
  _FakeChatbotReplyService({
    this.response = 'Here is the current menu information.',
  });

  final String response;
  String? lastQuestion;
  List<MenuProduct> lastProducts = [];

  @override
  Future<String> replyTo(String question, List<MenuProduct> products) async {
    lastQuestion = question;
    lastProducts = products;
    return response;
  }
}

class _FailingChatbotReplyService implements ChatbotReplyService {
  @override
  Future<String> replyTo(String question, List<MenuProduct> products) {
    throw StateError(
      'Set GROQ_WORKER_URL when building the app to enable the assistant.',
    );
  }
}

class _UnexpectedFailingChatbotReplyService implements ChatbotReplyService {
  @override
  Future<String> replyTo(String question, List<MenuProduct> products) {
    throw StateError('test failure');
  }
}

bool _hasBoldText(InlineSpan span, String text) {
  if (span is! TextSpan) return false;
  if (span.text?.contains(text) == true &&
      span.style?.fontWeight == FontWeight.w800) {
    return true;
  }
  return span.children?.any((child) => _hasBoldText(child, text)) ?? false;
}

bool _hasItalicText(InlineSpan span, String text) {
  if (span is! TextSpan) return false;
  if (span.text?.contains(text) == true &&
      span.style?.fontStyle == FontStyle.italic) {
    return true;
  }
  return span.children?.any((child) => _hasItalicText(child, text)) ?? false;
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

Finder _findChatMessage(String text) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText() == text,
);

Future<void> _waitForChatPersistence(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });
}
