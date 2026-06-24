import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/reviews_provider.dart';
import '../widgets/rating_stars.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/theme/app_text_styles.dart';

class ReviewScreen extends StatefulWidget {
  final String bookingId;
  final String walkerId;
  final String walkerUserId;

  const ReviewScreen({
    super.key,
    required this.bookingId,
    required this.walkerId,
    required this.walkerUserId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  bool _alreadyReviewed = false;

  @override
  void initState() {
    super.initState();
    _checkAlreadyReviewed();
  }

  Future<void> _checkAlreadyReviewed() async {
    final reviewed = await context
        .read<ReviewsProvider>()
        .hasReviewed(widget.bookingId);
    if (mounted) setState(() => _alreadyReviewed = reviewed);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona una calificación.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final profile = context.read<ProfileProvider>();
    final ownerId = profile.owner?.id ?? '';
    final ownerName = profile.owner?.name ?? auth.userModel?.email ?? '';

    final ok = await context.read<ReviewsProvider>().createReview(
          walkerId: widget.walkerId,
          ownerId: ownerId,
          bookingId: widget.bookingId,
          rating: _rating,
          comment: _commentCtrl.text.trim().isEmpty
              ? null
              : _commentCtrl.text.trim(),
          ownerName: ownerName,
        );
    setState(() => _submitting = false);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Calificación enviada! Gracias por tu opinión.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al enviar la calificación. Inténtalo de nuevo.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Calificar servicio'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _alreadyReviewed
            ? Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 64),
                    const SizedBox(height: 16),
                    Text('Ya calificaste este servicio.',
                        style: AppTextStyles.heading3,
                        textAlign: TextAlign.center),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('¿Cómo fue tu experiencia?',
                      style: AppTextStyles.heading2),
                  const SizedBox(height: 8),
                  Text(
                    'Tu opinión ayuda a otros dueños a elegir el mejor paseador.',
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        Text('Calificación', style: AppTextStyles.heading3),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _rating = i + 1),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Icon(
                                  i < _rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: AppColors.accent,
                                  size: 44,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        if (_rating > 0)
                          Text(
                            _ratingLabel(_rating),
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.accent),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Comentario (opcional)',
                      style: AppTextStyles.heading3),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText:
                          'Cuéntanos cómo fue el servicio...',
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomElevatedButton(
                    label: 'Enviar calificación',
                    isLoading: _submitting,
                    onPressed: _submit,
                  ),
                ],
              ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }
}
