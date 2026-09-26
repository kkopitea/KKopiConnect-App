import 'order_draft.dart';

class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.items,
    required this.fulfillment,
    required this.paymentMethod,
    required this.instructions,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final List<OrderDraft> items;
  final String fulfillment;
  final String paymentMethod;
  final String instructions;
  final String status;
  final DateTime createdAt;

  int get total => items.fold<int>(0, (sum, item) => sum + item.total);

  String get formattedId => '#$id';

  PlacedOrder copyWith({String? status}) => PlacedOrder(
    id: id,
    items: items,
    fulfillment: fulfillment,
    paymentMethod: paymentMethod,
    instructions: instructions,
    status: status ?? this.status,
    createdAt: createdAt,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'items': items.map((item) => item.toMap()).toList(),
    'fulfillment': fulfillment,
    'paymentMethod': paymentMethod,
    'instructions': instructions,
    'status': status,
    'total': total,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory PlacedOrder.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'] as List? ?? const [];
    final items = rawItems
        .whereType<Map>()
        .map((item) => OrderDraft.fromMap(Map<String, dynamic>.from(item)))
        .toList();

    return PlacedOrder(
      id: map['id'] as String? ?? '',
      items: List.unmodifiable(items),
      fulfillment: map['fulfillment'] as String? ?? 'Pickup',
      paymentMethod: map['paymentMethod'] as String? ?? 'Pay At The Counter',
      instructions: map['instructions'] as String? ?? '',
      status: map['status'] as String? ?? 'Pending',
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
