import 'package:flutter_test/flutter_test.dart';
import 'package:kkopiconnect_app/data/menu_catalog.dart';

void main() {
  test('parses the admin productData schema and legacy web aliases', () {
    final adminProduct = MenuProduct.fromFirestore('admin-product', {
      'name': 'Iced Matcha',
      'description': 'Matcha and milk over ice.',
      'categoryId': 'Coffee',
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
      'category': 'Milktea',
      'price': 55,
      'available': true,
    });

    expect(adminProduct?.price, 72);
    expect(adminProduct?.categoryId, 'coffee');
    expect(adminProduct?.categoryIds, ['coffee']);
    expect(adminProduct?.sizes, [('Large', 10)]);
    expect(adminProduct?.availableSizes, [('16oz', 0), ('22oz', 10)]);
    expect(adminProduct?.sugarLevels, ['0%', '50%']);
    expect(webProduct?.price, 55);
    expect(webProduct?.categoryId, 'milktea');
    expect(webProduct?.availableSizes, [('16oz', 0), ('22oz', 0)]);
  });

  test('available sizes always exposes only 16oz and 22oz', () {
    final product = MenuProduct(
      id: 'sized',
      name: 'Sized drink',
      description: '',
      price: 50,
      categoryId: 'coffee',
      categoryIds: const ['coffee'],
      sizes: const [('22 oz', 20), ('16oz', 5), ('32oz', 30)],
    );

    expect(product.availableSizes, [('16oz', 5), ('22oz', 20)]);
  });

  test('does not expose unavailable or malformed products', () {
    expect(
      MenuProduct.fromFirestore('unavailable', {
        'name': 'Hidden drink',
        'price': 40,
        'category': 'Coffee',
        'available': false,
      }),
      isNull,
    );
    expect(
      MenuProduct.fromFirestore('invalid', {
        'name': 'Invalid price',
        'price': '40',
        'category': 'Coffee',
        'available': true,
      }),
      isNull,
    );
  });
}
