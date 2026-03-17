import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_spacing.dart';
import 'app_secondary_button.dart';

class AppErrorState extends StatelessWidget {
  final String title;
  final String? message;
  final String retryLabel;
  final VoidCallback? onRetry;

  const AppErrorState({
    super.key,
    this.title = 'Hi ha hagut un problema',
    this.message,
    this.retryLabel = 'Torna-ho a provar',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleLarge,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppSecondaryButton(
                label: retryLabel,
                onPressed: onRetry,
                icon: Icons.refresh_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}