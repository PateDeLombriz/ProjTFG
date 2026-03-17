import 'package:flutter/material.dart';

import '../themes/app_colors.dart';
import '../themes/app_radius.dart';
import '../themes/app_spacing.dart';

enum AppStatusType {
  neutral,
  info,
  success,
  warning,
  error,
}

class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusType type;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.type = AppStatusType.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final style = _resolveColors(type);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: style.$1,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: style.$2,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: style.$3,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  (Color, Color, Color) _resolveColors(AppStatusType type) {
    switch (type) {
      case AppStatusType.info:
        return (AppColors.infoSoft, AppColors.infoSoft, AppColors.info);
      case AppStatusType.success:
        return (AppColors.successSoft, AppColors.successSoft, AppColors.success);
      case AppStatusType.warning:
        return (AppColors.warningSoft, AppColors.warningSoft, AppColors.warning);
      case AppStatusType.error:
        return (AppColors.errorSoft, AppColors.errorSoft, AppColors.error);
      case AppStatusType.neutral:
        return (
          AppColors.surfaceMuted,
          AppColors.border,
          AppColors.textSecondary,
        );
    }
  }
}