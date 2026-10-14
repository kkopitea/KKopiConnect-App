import 'package:flutter_test/flutter_test.dart';
import 'package:kkopiconnect_app/data/menu_catalog.dart';
import 'package:kkopiconnect_app/data/order_draft.dart';

void main() {
  test('order lines retain saved product details after menu updates', () {
    final originalProducts = menuProducts;
    final originalProduct = originalProducts.first;
    final savedLine = OrderDraft(product: originalProduct).toMap();
    menuProducts = [
      MenuProduct(
        id: originalProduct.id,
        name: 'Updated menu name',
        description: 'Updated menu description',
        price: originalProduct.price + 100,
        categoryId: originalProduct.categoryId,
        categoryIds: originalProduct.categoryIds,
      ),
    ];

    try {
      final restored = OrderDraft.fromMap(savedLine);

      expect(restored.product.name, originalProduct.name);
      expect(restored.product.price, originalProduct.price);
      expect(restored.total, originalProduct.price);
    } finally {
      menuProducts = originalProducts;
    }
  });
}
