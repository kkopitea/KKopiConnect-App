class DrinkExtra {
  const DrinkExtra({
    required this.id,
    required this.name,
    required this.price,
    this.isAvailable = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final int price;
  final bool isAvailable;
  final int sortOrder;

  Map<String, Object?> toMap() => {
    'name': name,
    'price': price,
    'isAvailable': isAvailable,
    'sortOrder': sortOrder,
  };

  factory DrinkExtra.fromMap(String id, Map<String, dynamic> map) =>
      DrinkExtra(
        id: id,
        name: map['name'] as String? ?? '',
        price: (map['price'] as num?)?.toInt() ?? 0,
        isAvailable: map['isAvailable'] as bool? ?? true,
        sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      );
}
