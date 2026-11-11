import 'package:flutter/material.dart';

import '../app_colors.dart';

class NotificationAnnouncementScreen extends StatelessWidget {
  const NotificationAnnouncementScreen({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.imageUrls = const [],
    this.eyebrow = '',
    this.version = '',
    this.buttonLabel = 'Browse menu',
    this.promotionDates = '',
    this.onAction,
  });

  final String title;
  final String message;
  final String type;
  final List<String> imageUrls;
  final String eyebrow;
  final String version;
  final String buttonLabel;
  final String promotionDates;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final imageUrl = imageUrls
        .map((url) => url.trim())
        .firstWhere((url) => url.isNotEmpty, orElse: () => '');

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: Text(type == 'Promotion' ? 'Promotion' : 'System')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                imageUrl,
                height: 230,
                width: double.infinity,
                fit: BoxFit.cover,
                semanticLabel: type == 'Promotion'
                    ? 'Promotion image'
                    : 'Announcement image',
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: AppColors.orangeTint,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.orange,
                    size: 44,
                  ),
                ),
              ),
            )
          else
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.orangeTint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                type == 'Promotion'
                    ? Icons.local_offer_rounded
                    : Icons.system_update_rounded,
                color: AppColors.orange,
                size: 54,
              ),
            ),
          const SizedBox(height: 20),
          if (eyebrow.trim().isNotEmpty)
            Text(
              eyebrow.trim().toUpperCase(),
              style: const TextStyle(
                color: AppColors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          if (type == 'System' && version.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.orangeTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    'Version ${version.trim()}',
                    style: const TextStyle(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          if (type == 'Promotion' && promotionDates.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    promotionDates,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (onAction != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.restaurant_menu_rounded),
              label: Text(
                buttonLabel.trim().isEmpty ? 'Browse menu' : buttonLabel,
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
