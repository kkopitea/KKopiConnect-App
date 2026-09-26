import 'menu_catalog.dart';

class OrderDraft {
  const OrderDraft({
    required this.product,
    this.quantity = 1,
    this.size = 'Regular',
    this.sizePrice,
    this.sugar = '50%',
    this.ice = '50%',
    this.addIns = const {},
    this.addOns = const {},
  });

  final MenuProduct product;
  final int quantity;
  final String size;
  final int? sizePrice;
  final String sugar;
  final String ice;
  final Set<String> addIns;
  final Set<String> addOns;

  int get unitPrice => sizePrice ?? product.price;

  int get addOnTotal =>
      addOns.fold<int>(0, (total, addOn) => total + (addOnPrices[addOn] ?? 0));

  int get addInTotal =>
      addIns.fold<int>(0, (total, addIn) => total + (addInPrices[addIn] ?? 0));

  int get total => (unitPrice + addInTotal + addOnTotal) * quantity;

  OrderDraft copyWith({
    int? quantity,
    String? size,
    int? sizePrice,
    String? sugar,
    String? ice,
    Set<String>? addIns,
    Set<String>? addOns,
  }) {
    return OrderDraft(
      product: product,
      quantity: quantity ?? this.quantity,
      size: size ?? this.size,
      sizePrice: sizePrice ?? this.sizePrice,
      sugar: sugar ?? this.sugar,
      ice: ice ?? this.ice,
      addIns: addIns ?? this.addIns,
      addOns: addOns ?? this.addOns,
    );
  }
}

const addOnPrices = <String, int>{
  'Coffee Jelly': 30,
  'Pudding': 50,
  'Cream Cheese': 40,
};

const addInPrices = <String, int>{
  'Extra syrup': 5,
  'Pearls': 20,
  'Cream cap': 20,
};
