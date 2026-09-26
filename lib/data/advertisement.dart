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
  };

  factory Advertisement.fromMap(String id, Map<String, dynamic> map) =>
      Advertisement(
        id: id,
        title: map['title'] as String? ?? '',
        eyebrow: map['eyebrow'] as String? ?? '',
        description: map['description'] as String? ?? '',
        buttonLabel: map['buttonLabel'] as String? ?? 'Browse menu',
        imageUrl: map['imageUrl'] as String? ?? '',
        isActive: map['isActive'] as bool? ?? false,
        sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
        productId: map['productId'] as String? ?? '',
      );
}
