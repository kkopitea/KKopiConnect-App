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
    this.addInUnitPrices = const {},
    this.addOnUnitPrices = const {},
  });

  final MenuProduct product;
  final int quantity;
  final String size;
  final int? sizePrice;
  final String sugar;
  final String ice;
  final Set<String> addIns;
  final Set<String> addOns;
  final Map<String, int> addInUnitPrices;
  final Map<String, int> addOnUnitPrices;

  int get unitPrice => sizePrice ?? product.price;

  int get addOnTotal =>
      addOns.fold<int>(
        0,
        (total, addOn) =>
            total + (addOnUnitPrices[addOn] ?? addOnPrices[addOn] ?? 0),
      );

  int get addInTotal =>
      addIns.fold<int>(
        0,
        (total, addIn) =>
            total + (addInUnitPrices[addIn] ?? addInPrices[addIn] ?? 0),
      );

  int get total => (unitPrice + addInTotal + addOnTotal) * quantity;

  Map<String, Object?> toMap() => {
    'productId': product.id,
    'productName': product.name,
    'productDescription': product.description,
    'productPrice': product.price,
    'productImageAsset': product.imageAsset,
    'productImageUrl': product.imageUrl,
    'quantity': quantity,
    'size': size,
    'sizePrice': sizePrice,
    'sugar': sugar,
    'ice': ice,
    'addIns': addIns.toList(),
    'addOns': addOns.toList(),
    'addInUnitPrices': addInUnitPrices,
    'addOnUnitPrices': addOnUnitPrices,
    'total': total,
  };

  factory OrderDraft.fromMap(Map<String, dynamic> map) {
    final productId = map['productId'] as String? ?? 'unknown-product';
    final matchingProducts = menuProducts.where(
      (product) => product.id == productId,
    );
    final product = matchingProducts.isEmpty
        ? MenuProduct(
            id: productId,
            name: map['productName'] as String? ?? 'Menu item',
            description: map['productDescription'] as String? ?? '',
            price: (map['productPrice'] as num?)?.toInt() ?? 0,
            categoryId: '',
            categoryIds: const [],
            imageAsset:
                map['productImageAsset'] as String? ??
                'assets/images/welcome_drink.png',
            imageUrl: map['productImageUrl'] as String?,
          )
        : matchingProducts.first;

    return OrderDraft(
      product: product,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      size: map['size'] as String? ?? 'Regular',
      sizePrice: (map['sizePrice'] as num?)?.toInt(),
      sugar: map['sugar'] as String? ?? '50%',
      ice: map['ice'] as String? ?? '50%',
      addIns: Set<String>.from(map['addIns'] as List? ?? const []),
      addOns: Set<String>.from(map['addOns'] as List? ?? const []),
      addInUnitPrices: _readPrices(map['addInUnitPrices']),
      addOnUnitPrices: _readPrices(map['addOnUnitPrices']),
    );
  }

  OrderDraft copyWith({
    int? quantity,
    String? size,
    int? sizePrice,
    String? sugar,
    String? ice,
    Set<String>? addIns,
    Set<String>? addOns,
    Map<String, int>? addInUnitPrices,
    Map<String, int>? addOnUnitPrices,
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
      addInUnitPrices: addInUnitPrices ?? this.addInUnitPrices,
      addOnUnitPrices: addOnUnitPrices ?? this.addOnUnitPrices,
    );
  }

  static Map<String, int> _readPrices(Object? rawPrices) {
    if (rawPrices is! Map) return const {};
    return rawPrices.map<String, int>((key, value) {
      return MapEntry(
        key.toString(),
        value is num ? value.toInt() : 0,
      );
    });
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
