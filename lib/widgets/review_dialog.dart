import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/helpers.dart';
import '../models/booking_model.dart';
import '../providers/artisan_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import 'custom_button.dart';
import 'custom_text_field.dart';

class ReviewDialog extends StatefulWidget {
  const ReviewDialog({super.key, required this.booking});

  final BookingModel booking;

  static Future<bool> show(BuildContext context, BookingModel booking) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReviewDialog(booking: booking),
    );
    return result ?? false;
  }

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      Helpers.showSnackBar(context, 'Please select a star rating', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Please sign in to submit a review', isError: true);
        Navigator.pop(context, false);
      }
      return;
    }

    final success = await context.read<BookingProvider>().submitReview(
          bookingId: widget.booking.id,
          customerId: user.id,
          customerName: user.name,
          rating: _rating.toDouble(),
          comment: _commentController.text,
        );

    if (!mounted) return;

    if (success) {
      await context.read<ArtisanProvider>().refreshArtisan(widget.booking.artisanId);
      if (mounted) Navigator.pop(context, true);
    } else {
      final error = context.read<BookingProvider>().errorMessage;
      if (error != null) {
        Helpers.showSnackBar(context, error, isError: true);
      }
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Write Review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How was your experience with this ${widget.booking.serviceCategory} service?',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _StarRatingPicker(
              rating: _rating,
              onRatingChanged: (value) => setState(() => _rating = value),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Comment (optional)',
              controller: _commentController,
              hint: 'Share details about the service...',
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Skip'),
        ),
        CustomButton(
          label: 'Submit Review',
          isFullWidth: false,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
          icon: Icons.star,
        ),
      ],
    );
  }
}

class _StarRatingPicker extends StatelessWidget {
  const _StarRatingPicker({
    required this.rating,
    required this.onRatingChanged,
  });

  final int rating;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = starValue <= rating;

        return IconButton(
          onPressed: () => onRatingChanged(starValue),
          icon: Icon(
            isFilled ? Icons.star : Icons.star_border,
            size: 40,
            color: isFilled ? AppConstants.accentGold : Colors.grey.shade400,
          ),
        );
      }),
    );
  }
}
