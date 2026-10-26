class Advertisement {
  const Advertisement({
    this.id = '',
    required this.title,
    required this.eyebrow,
    required this.description,
    required this.buttonLabel,
    required this.imageUrl,
    required this.isActive,
    required this.sortOrder,
    this.productId = '',
    this.imageUrls = const [],
    this.productIds = const [],
    this.isBuyOneTakeOne = false,
  });

  final String id;
  final String title;
  final String eyebrow;
  final String description;
  final String buttonLabel;
  final String imageUrl;
  final bool isActive;
  final int sortOrder;
  final String productId;
  final List<String> imageUrls;
  final List<String> productIds;
  final bool isBuyOneTakeOne;

  List<String> get campaignImageUrls {
    final urls = imageUrls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList(growable: false);
    if (urls.isNotEmpty) return urls;
    final legacyUrl = imageUrl.trim();
    return legacyUrl.isEmpty ? const [] : [legacyUrl];
  }

  List<String> get selectedProductIds {
    final ids = productIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (ids.isNotEmpty) return ids;
    final legacyId = productId.trim();
    return legacyId.isEmpty ? const [] : [legacyId];
  }

  Advertisement copyWith({bool? isActive}) => Advertisement(
    id: id,
    title: title,
    eyebrow: eyebrow,
    description: description,
    buttonLabel: buttonLabel,
    imageUrl: imageUrl,
    isActive: isActive ?? this.isActive,
    sortOrder: sortOrder,
    productId: productId,
    imageUrls: imageUrls,
    productIds: productIds,
    isBuyOneTakeOne: isBuyOneTakeOne,
  );

  Map<String, Object?> toMap() => {
    'title': title,
    'eyebrow': eyebrow,
    'description': description,
    'buttonLabel': buttonLabel,
    'imageUrl': imageUrl,
    'isActive': isActive,
    'sortOrder': sortOrder,
    'productId': productId,
    'imageUrls': imageUrls,
    'productIds': productIds,
    'isBuyOneTakeOne': isBuyOneTakeOne,
  };

  factory Advertisement.fromMap(String id, Map<String, dynamic> map) {
    List<String> readStringList(Object? value) => value is List
        ? value.whereType<String>().map((item) => item.trim()).toList()
        : const [];

    return Advertisement(
      id: id,
      title: map['title'] is String ? map['title'] as String : '',
      eyebrow: map['eyebrow'] is String ? map['eyebrow'] as String : '',
      description: map['description'] is String
          ? map['description'] as String
          : '',
      buttonLabel: map['buttonLabel'] is String
          ? map['buttonLabel'] as String
          : 'Browse menu',
      imageUrl: map['imageUrl'] is String ? map['imageUrl'] as String : '',
      isActive: map['isActive'] == true,
      sortOrder: map['sortOrder'] is num
          ? (map['sortOrder'] as num).toInt()
          : 0,
      productId: map['productId'] is String ? map['productId'] as String : '',
      imageUrls: readStringList(map['imageUrls']),
      productIds: readStringList(map['productIds']),
      isBuyOneTakeOne: map['isBuyOneTakeOne'] == true,
    );
  }
}
