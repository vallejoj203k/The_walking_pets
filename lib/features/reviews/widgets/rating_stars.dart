import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 18,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? AppColors.accent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = rating >= i + 1;
        final half = !filled && rating >= i + 0.5;
        return Icon(
          filled
              ? Icons.star
              : half
                  ? Icons.star_half
                  : Icons.star_border,
          color: starColor,
          size: size,
        );
      }),
    );
  }
}
