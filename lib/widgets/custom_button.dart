import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

enum CustomButtonVariant { primary, secondary, outlined, text }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = CustomButtonVariant.primary,
    this.icon,
    this.isFullWidth = true,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final CustomButtonVariant variant;
  final IconData? icon;
  final bool isFullWidth;
  final double height;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _loaderColor(),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    // Never pass Size(infinity, ...) into button themes — that crashes inside
    // Rows / unbounded parents. Stretch with SizedBox instead when needed.
    final minSize = Size(isFullWidth ? 64 : 0, height);

    final button = switch (variant) {
      CustomButtonVariant.primary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(minimumSize: minSize),
          child: child,
        ),
      CustomButtonVariant.secondary => ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.accentGold,
            foregroundColor: AppConstants.darkText,
            minimumSize: minSize,
          ),
          child: child,
        ),
      CustomButtonVariant.outlined => OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConstants.primaryGreen,
            side: const BorderSide(color: AppConstants.primaryGreen),
            minimumSize: minSize,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: child,
        ),
      CustomButtonVariant.text => TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.primaryGreen,
            minimumSize: minSize,
          ),
          child: child,
        ),
    };

    if (!isFullWidth) return button;
    return SizedBox(width: double.infinity, height: height, child: button);
  }

  Color _loaderColor() {
    return switch (variant) {
      CustomButtonVariant.primary => Colors.white,
      CustomButtonVariant.secondary => AppConstants.darkText,
      CustomButtonVariant.outlined => AppConstants.primaryGreen,
      CustomButtonVariant.text => AppConstants.primaryGreen,
    };
  }
}
