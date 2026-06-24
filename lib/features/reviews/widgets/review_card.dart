import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/review_model.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';
import 'rating_stars.dart';

class ReviewCard extends StatelessWidget {
  final ReviewModel review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy', 'es');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (review.ownerName?.isNotEmpty == true
                            ? review.ownerName![0]
                            : 'D')
                        .toUpperCase(),
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.ownerName ?? 'Dueño',
                          style: AppTextStyles.body),
                      Text(fmt.format(review.createdAt),
                          style: AppTextStyles.caption),
                    ],
                  ),
                ),
                RatingStars(rating: review.rating.toDouble(), size: 16),
              ],
            ),
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(review.comment!, style: AppTextStyles.bodySecondary),
            ],
          ],
        ),
      ),
    );
  }
}
