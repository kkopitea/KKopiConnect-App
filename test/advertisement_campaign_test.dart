import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kkopiconnect_app/data/advertisement.dart';
import 'package:kkopiconnect_app/data/advertisement_repository.dart';
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
        'productId': 'legacy-product',
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
      expect(advertisement.isBuyOneTakeOne, isTrue);
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
  });

  testWidgets('carousel filters inactive campaigns and shows BOGO badge', (
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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdvertisementCarousel(
            advertisements: Stream.value([activeCampaign, inactiveCampaign]),
            onSelect: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Active special'), findsOneWidget);
    expect(find.text('Hidden special'), findsNothing);
    expect(find.text('Buy One, Take One'), findsOneWidget);
    expect(find.bySemanticsLabel('Campaign image 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Campaign image 2'), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image).first).fit, BoxFit.contain);

    await tester.drag(find.byType(PageView).last, const Offset(-180, 0));
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
}
