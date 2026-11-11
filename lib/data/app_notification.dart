class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isActive,
    required this.sortOrder,
    this.iconKey = 'notifications',
    this.imageUrl = '',
    this.version = '',
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool isActive;
  final int sortOrder;
  final String iconKey;
  final String imageUrl;
  final String version;

  static AppNotification? fromFirestore(String id, Map<String, dynamic> data) {
    final title = data['title'];
    final type = data['type'];
    if (title is! String || title.trim().isEmpty || type is! String) {
      return null;
    }
    final normalizedType = type.trim().toLowerCase();
    final storedMessage = data['message'];
    final description = data['description'];
    final message = storedMessage is String && storedMessage.trim().isNotEmpty
        ? storedMessage
        : normalizedType == 'promotion' && description is String
        ? description
        : null;
    if (message is! String || message.trim().isEmpty) return null;
    final sortOrder = data['sortOrder'];
    final iconKey = data['iconKey'];

    return AppNotification(
      id: id,
      title: title.trim(),
      message: message.trim(),
      type: normalizedType == 'promotion' ? 'Promotion' : 'System',
      isActive: data['isActive'] == true,
      sortOrder: sortOrder is num ? sortOrder.toInt() : 0,
      iconKey: iconKey is String ? iconKey : 'notifications',
      imageUrl: data['imageUrl'] is String
          ? (data['imageUrl'] as String).trim()
          : '',
      version: data['version'] is String
          ? (data['version'] as String).trim()
          : '',
    );
  }
}
