import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kkopiconnect_app/data/advertisement.dart';
import 'package:kkopiconnect_app/data/advertisement_repository.dart';
import 'package:kkopiconnect_app/screens/categories_screen.dart';
import 'package:kkopiconnect_app/screens/home_screen.dart';
import 'package:kkopiconnect_app/widgets/advertisement_carousel.dart';

void main() {
  group('Advertisement campaign parsing', () {
    test('supports legacy single image and product fields', () {
      final advertisement = Advertisement.fromMap('legacy', {
        'title': 'Legacy campaign',
        'isActive': true,
        'imageUrls': [],
        'productIds': [],
        'imageUrl': ' https://example.com/banner.png ',
        'productId': ' legacy-product ',
      });

      expect(advertisement.campaignImageUrls, [
        'https://example.com/banner.png',
      ]);
      expect(advertisement.selectedProductIds, ['legacy-product']);
      expect(advertisement.isActive, isTrue);
      expect(advertisement.isBuyOneTakeOne, isFalse);
      expect(advertisement.effectiveButtonActionType, 'product');
    });

    test('reads multiple campaign images and selected products', () {
      final advertisement = Advertisement.fromMap('campaign', {
        'title': 'Multi-item campaign',
        'isActive': true,
        'imageUrls': [
          'https://example.com/one.png',
          'https://example.com/two.png',
        ],
        'imageUrl': 'https://example.com/legacy.png',
        'productIds': ['first-product', 'second-product'],
        'productId': ' legacy-product ',
        'buttonActionType': 'category',
        'buttonTarget': 'iced_lattes',
        'isBuyOneTakeOne': true,
      });

      expect(advertisement.campaignImageUrls, [
        'https://example.com/one.png',
        'https://example.com/two.png',
      ]);
      expect(advertisement.selectedProductIds, [
        'first-product',
        'second-product',
      ]);
      expect(advertisement.productIdsForNavigation, [
        'legacy-product',
        'first-product',
        'second-product',
      ]);
      expect(advertisement.isBuyOneTakeOne, isTrue);
      expect(advertisement.effectiveButtonActionType, 'category');
      expect(advertisement.buttonTarget, 'iced_lattes');
    });

    test('reads promotions created by the web admin', () {
      final promotion = Advertisement.fromMap('promotion-cheso-de-bola', {
        'title': 'Cheso de bola',
        'eyebrow': 'HOLIDAY SPECIAL',
        'description': 'Try our Cheso de bola special.',
        'buttonLabel': 'Browse menu',
        'imageUrl': 'https://example.com/cheso-de-bola.png',
        'imageUrls': ['https://example.com/cheso-de-bola.png'],
        'productId': 'cheso-de-bola-product',
        'productIds': ['cheso-de-bola-product'],
        'isActive': true,
        'sortOrder': 1,
        'startAt': DateTime(2026, 11, 10).toIso8601String(),
        'endAt': DateTime(2026, 11, 12).toIso8601String(),
      });

      expect(promotion.title, 'Cheso de bola');
      expect(promotion.isAvailableAt(DateTime(2026, 11, 11)), isTrue);
      expect(promotion.campaignImageUrls, [
        'https://example.com/cheso-de-bola.png',
      ]);
      expect(promotion.selectedProductIds, ['cheso-de-bola-product']);
    });

    test('handles malformed optional values and orders campaigns safely', () {
      final malformed = Advertisement.fromMap('z', {
        'title': 42,
        'isActive': 'true',
        'sortOrder': 'first',
        'imageUrls': [' ', 4],
        'productIds': 'not-a-list',
        'isBuyOneTakeOne': 'yes',
      });
      final ordered = AdvertisementRepository.sort([
        malformed,
        Advertisement.fromMap('b', {
          'title': 'Second',
          'isActive': true,
          'sortOrder': 2,
        }),
        Advertisement.fromMap('a', {
          'title': 'First',
          'isActive': true,
          'sortOrder': 1,
        }),
      ]);

      expect(malformed.title, isEmpty);
      expect(malformed.isActive, isFalse);
      expect(malformed.sortOrder, 0);
      expect(malformed.campaignImageUrls, isEmpty);
      expect(malformed.selectedProductIds, isEmpty);
      expect(malformed.isBuyOneTakeOne, isFalse);
      expect(ordered.map((campaign) => campaign.id), ['z', 'a', 'b']);
    });

    test('promotion date range controls campaign availability', () {
      final startAt = DateTime(2026, 11, 10, 9);
      final endAt = DateTime(2026, 11, 12, 18);
      final campaign = Advertisement.fromMap('scheduled', {
        'title': 'Scheduled promotion',
        'isActive': true,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
      });

      expect(campaign.startAt, startAt);
      expect(campaign.endAt, endAt);
      expect(campaign.isAvailableAt(startAt), isTrue);
      expect(campaign.isAvailableAt(endAt), isFalse);
      expect(
        campaign.isAvailableAt(startAt.subtract(const Duration(seconds: 1))),
        isFalse,
      );

      final saved = campaign.toMap();
      expect(saved['startAt'], isNotNull);
      expect(saved['endAt'], isNotNull);
    });
  });

  testWidgets('carousel fills card with image and selects campaign on tap', (
    tester,
  ) async {
    final activeCampaign = Advertisement.fromMap('active', {
      'title': 'Active special',
      'isActive': true,
      'isBuyOneTakeOne': true,
      'imageUrls': [
        'https://example.com/first.png',
        'https://example.com/second.png',
      ],
    });
    final inactiveCampaign = Advertisement.fromMap('inactive', {
      'title': 'Hidden special',
      'isActive': false,
    });

    Advertisement? selectedAdvertisement;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvertisementCarousel(
            advertisements: Stream.value([activeCampaign, inactiveCampaign]),
            onSelect: (advertisement) => selectedAdvertisement = advertisement,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Active special'), findsNothing);
    expect(find.text('Hidden special'), findsNothing);
    expect(find.text('Buy One, Take One'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.bySemanticsLabel('Campaign image 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Campaign image 2'), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image).first).fit, BoxFit.cover);

    await tester.tapAt(tester.getCenter(find.byType(PageView).first));
    await tester.pump();
    expect(selectedAdvertisement?.id, 'active');

    await tester.drag(find.byType(PageView).last, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Semantics>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.label == 'Campaign image 2',
            ),
          )
          .properties
          .selected,
      isTrue,
    );
  });

  testWidgets('promotion action opens the admin-selected destination', (
    tester,
  ) async {
    var selectedTab = -1;
    final campaign = Advertisement.fromMap('order-now', {
      'title': 'Order now',
      'isActive': true,
      'buttonLabel': 'Order now',
      'buttonActionType': 'orders',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          onSeeAllCategories: () {},
          onNavigateTab: (index) => selectedTab = index,
          advertisements: Stream.value([campaign]),
        ),
      ),
    );
    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(PageView).first));
    await tester.pumpAndSettle();

    expect(selectedTab, 3);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'stale campaign links do not navigate to categories or show a sheet',
    (tester) async {
      final campaign = Advertisement.fromMap('stale-link', {
        'title': 'Unavailable item',
        'isActive': true,
        'productId': 'missing-product',
      });

      await tester.pumpWidget(
        MaterialApp(
          home: CategoriesScreen(advertisements: Stream.value([campaign])),
        ),
      );
      await tester.pump();
      await tester.tapAt(tester.getCenter(find.byType(PageView)));
      await tester.pump();

      expect(find.text('Browse categories'), findsNothing);
      expect(
        find.text('This advertised product is currently unavailable.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('stale campaign links on home do not navigate to categories', (
    tester,
  ) async {
    var categoriesOpened = false;
    final campaign = Advertisement.fromMap('stale-link', {
      'title': 'Unavailable item',
      'isActive': true,
      'productId': 'missing-product',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          onSeeAllCategories: () => categoriesOpened = true,
          advertisements: Stream.value([campaign]),
        ),
      ),
    );
    await tester.pump();
    await tester.tapAt(tester.getCenter(find.byType(PageView)));
    await tester.pump();

    expect(categoriesOpened, isFalse);
    expect(
      find.text('This advertised product is currently unavailable.'),
      findsOneWidget,
    );
  });
}
