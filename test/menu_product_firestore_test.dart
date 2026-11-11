import 'package:flutter_test/flutter_test.dart';
import 'package:kkopiconnect_app/data/menu_catalog.dart';

void main() {
  test('parses the admin productData schema and legacy web aliases', () {
    final adminProduct = MenuProduct.fromFirestore('admin-product', {
      'name': 'Iced Matcha',
      'description': 'Matcha and milk over ice.',
      'categoryId': 'Amerikano',
      'basePrice': 72,
      'imageUrl': 'https://example.com/matcha.png',
      'isAvailable': true,
      'sizes': [
        {'name': 'Large', 'additionalPrice': 10},
      ],
      'sugarLevels': ['0%', '50%'],
    });
    final webProduct = MenuProduct.fromFirestore('web-product', {
      'name': 'Classic Tea',
      'description': 'Tea with milk.',
      'category': 'Bubble Teas',
      'price': 55,
      'available': true,
    });
    final legacyProduct = MenuProduct.fromFirestore('legacy-product', {
      'name': 'Legacy Coffee',
      'category': 'Coffee',
      'price': 55,
      'available': true,
    });

    expect(adminProduct?.price, 72);
    expect(adminProduct?.categoryId, 'amerikano');
    expect(adminProduct?.categoryIds, ['amerikano']);
    expect(adminProduct?.sizes, [('Large', 10)]);
    expect(adminProduct?.availableSizes, [('16oz', 0), ('22oz', 10)]);
    expect(adminProduct?.sugarLevels, ['0%', '50%']);
    expect(webProduct?.price, 55);
    expect(webProduct?.categoryId, 'bubble_teas');
    expect(webProduct?.availableSizes, [('16oz', 0), ('22oz', 0)]);
    expect(legacyProduct?.categoryId, 'amerikano');
  });

  test('parses product-specific add-ons from the web admin schema', () {
    final product = MenuProduct.fromFirestore('burat-ni-jian', {
      'name': 'BURAT NI JIAN',
      'categoryId': 'icedlattes',
      'basePrice': 120,
      'isAvailable': true,
      'addons': [
        {'name': 'Pearl', 'price': 10},
      ],
    });

    expect(product?.categoryId, 'iced_lattes');
    expect(product?.addOns.map((option) => (option.name, option.price)), [
      ('Pearl', 10),
    ]);
  });

  test('available sizes always exposes only 16oz and 22oz', () {
    final product = MenuProduct(
      id: 'sized',
      name: 'Sized drink',
      description: '',
      price: 50,
      categoryId: 'amerikano',
      categoryIds: const ['amerikano'],
      sizes: const [('22 oz', 20), ('16oz', 5), ('32oz', 30)],
    );

    expect(product.availableSizes, [('16oz', 5), ('22oz', 20)]);
  });

  test('does not expose unavailable or malformed products', () {
    expect(
      MenuProduct.fromFirestore('unavailable', {
        'name': 'Hidden drink',
        'price': 40,
        'category': 'Amerikano',
        'available': false,
      }),
      isNull,
    );
    expect(
      MenuProduct.fromFirestore('invalid', {
        'name': 'Invalid price',
        'price': '40',
        'category': 'Amerikano',
        'available': true,
      }),
      isNull,
    );
  });

  test('menu diagnostics distinguish empty, filtered, and failed reads', () {
    expect(
      const MenuProductsLoadStatus(
        phase: MenuProductsLoadPhase.loaded,
        documentCount: 0,
        availableCount: 0,
      ).message('kkopiconnect-2f015'),
      contains('products collection has no documents'),
    );
    expect(
      const MenuProductsLoadStatus(
        phase: MenuProductsLoadPhase.loaded,
        documentCount: 3,
        availableCount: 0,
      ).message('kkopiconnect-2f015'),
      contains('none are available to the app'),
    );
    expect(
      const MenuProductsLoadStatus(
        phase: MenuProductsLoadPhase.error,
        errorCode: 'permission-denied',
      ).message('kkopiconnect-2f015'),
      contains('permission-denied'),
    );
  });
}
