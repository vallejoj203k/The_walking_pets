import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reviews_provider.dart';
import '../widgets/review_card.dart';
import '../widgets/rating_stars.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class ReviewsListScreen extends StatefulWidget {
  final String walkerId;
  final String walkerName;

  const ReviewsListScreen({
    super.key,
    required this.walkerId,
    required this.walkerName,
  });

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReviewsProvider>().loadWalkerReviews(widget.walkerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'Reseñas de ${widget.walkerName}'),
      body: reviews.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (reviews.walkerReviews.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: AppColors.primary,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          reviews.averageRating.toStringAsFixed(1),
                          style: AppTextStyles.heading2
                              .copyWith(color: Colors.white, fontSize: 40),
                        ),
                        RatingStars(
                          rating: reviews.averageRating,
                          size: 24,
                          color: AppColors.accent,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reviews.walkerReviews.length} reseña${reviews.walkerReviews.length != 1 ? 's' : ''}',
                          style: AppTextStyles.body
                              .copyWith(color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: reviews.walkerReviews.isEmpty
                      ? const EmptyState(
                          message: 'Este paseador aún no tiene reseñas.',
                          icon: Icons.star_border,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: reviews.walkerReviews.length,
                          itemBuilder: (_, i) =>
                              ReviewCard(review: reviews.walkerReviews[i]),
                        ),
                ),
              ],
            ),
    );
  }
}
