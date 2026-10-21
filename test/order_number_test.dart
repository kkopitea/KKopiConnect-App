import 'package:flutter_test/flutter_test.dart';
import 'package:kkopiconnect_app/data/order_number.dart';
import 'package:kkopiconnect_app/data/placed_order.dart';

void main() {
  test('formats serials with a #KK prefix and at least three digits', () {
    expect(formatOrderNumber(1), '#KK001');
    expect(formatOrderNumber(28), '#KK028');
    expect(formatOrderNumber(1000), '#KK1000');
  });

  test('formats new and legacy order IDs without a duplicate prefix', () {
    final newOrder = PlacedOrder(
      id: '#KK001',
      items: [],
      fulfillment: 'Pickup',
      paymentMethod: 'Cash',
      instructions: '',
      status: 'Pending',
      createdAt: DateTime.utc(2025),
    );
    final legacyOrder = PlacedOrder(
      id: 'KK1735689600000',
      items: [],
      fulfillment: 'Pickup',
      paymentMethod: 'Cash',
      instructions: '',
      status: 'Pending',
      createdAt: DateTime.utc(2025),
    );

    expect(newOrder.formattedId, '#KK001');
    expect(legacyOrder.formattedId, '#KK1735689600000');
  });

  test('rejects non-positive serials', () {
    expect(() => formatOrderNumber(0), throwsArgumentError);
    expect(() => formatOrderNumber(-1), throwsArgumentError);
  });
}
