class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isActive,
    required this.sortOrder,
    this.iconKey = 'notifications',
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool isActive;
  final int sortOrder;
  final String iconKey;

  static AppNotification? fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final title = data['title'];
    final message = data['message'];
    final type = data['type'];
    if (title is! String ||
        title.trim().isEmpty ||
        message is! String ||
        type is! String) {
      return null;
    }
    return AppNotification(
      id: id,
      title: title.trim(),
      message: message.trim(),
      type: const {'Promotion', 'System'}.contains(type) ? type : 'System',
      isActive: data['isActive'] == true,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      iconKey: data['iconKey'] as String? ?? 'notifications',
    );
  }
}
