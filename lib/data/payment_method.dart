class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.name,
    required this.isActive,
    required this.sortOrder,
    this.instructions = '',
  });

  final String id;
  final String name;
  final bool isActive;
  final int sortOrder;
  final String instructions;

  static PaymentMethod? fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final name = data['name'];
    if (name is! String || name.trim().isEmpty) return null;
    return PaymentMethod(
      id: id,
      name: name.trim(),
      isActive: data['isActive'] == true,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      instructions: data['instructions'] as String? ?? '',
    );
  }

}

const defaultPaymentMethods = <PaymentMethod>[
  PaymentMethod(
    id: 'pay-at-counter',
    name: 'Pay At The Counter',
    isActive: true,
    sortOrder: 0,
  ),
  PaymentMethod(
    id: 'gcash',
    name: 'Gcash',
    isActive: true,
    sortOrder: 1,
  ),
];
