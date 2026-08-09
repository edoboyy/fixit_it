import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    this.message,
    this.fullScreen = false,
  });

  final String? message;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            color: AppConstants.primaryGreen,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          AnimatedOpacity(
            opacity: 1,
            duration: const Duration(milliseconds: 250),
            child: Text(
              message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );

    if (fullScreen) {
      return ColoredBox(
        color: theme.scaffoldBackgroundColor.withValues(alpha: 0.92),
        child: Center(child: content),
      );
    }

    return Center(child: content);
  }
}
