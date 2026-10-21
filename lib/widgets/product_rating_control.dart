import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../data/product_rating_repository.dart';

class ProductRatingControl extends StatelessWidget {
  const ProductRatingControl({
    super.key,
    required this.summary,
    required this.userRating,
    required this.onRate,
    this.isSubmitting = false,
  });

  final ProductRatingSummary summary;
  final int? userRating;
  final ValueChanged<int> onRate;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFFFA51D), size: 20),
            const SizedBox(width: 4),
            Text(
              summary.count == 0 ? '—' : summary.average.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 5),
            Text(
              '(${summary.count} ${summary.count == 1 ? 'rating' : 'ratings'})',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            if (isSubmitting) ...[
              const SizedBox(width: 8),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                tooltip: userRating == null
                    ? 'Rate $star out of 5 stars'
                    : 'Change rating to $star out of 5 stars',
                onPressed: isSubmitting ? null : () => onRate(star),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                iconSize: 24,
                color: const Color(0xFFFFA51D),
                icon: Icon(
                  userRating != null && star <= userRating!
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                ),
              ),
            const SizedBox(width: 6),
            Text(
              userRating == null
                  ? 'Rate this drink'
                  : 'Your rating: $userRating/5',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
