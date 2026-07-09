import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

enum JunaButtonVariant { primary, secondary, outline, ghost, danger }

class JunaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final JunaButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final IconData? icon;
  final double? width;
  final double height;
  final double? borderRadius;

  const JunaButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = JunaButtonVariant.primary,
    this.isLoading = false,
    this.fullWidth = true,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final isDisabled = onPressed == null || isLoading;
    final radius = borderRadius ?? AppRadius.lg;

    return SizedBox(
      width: fullWidth ? double.infinity : width,
      height: height,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Material(
          color: colors.background,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: isDisabled ? null : onPressed,
            borderRadius: BorderRadius.circular(radius),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                border: colors.border != null
                    ? Border.all(color: colors.border!, width: 1.5)
                    : null,
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.foreground,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 18, color: colors.foreground),
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Expanded(
                            child: Text(
                              label,
                              style: AppTypography.labelLarge.copyWith(
                                color: colors.foreground,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ButtonColors _getColors() {
    switch (variant) {
      case JunaButtonVariant.primary:
        return _ButtonColors(
          background: AppColors.accent,
          foreground: AppColors.white,
        );
      case JunaButtonVariant.secondary:
        return _ButtonColors(
          background: AppColors.primary,
          foreground: AppColors.white,
        );
      case JunaButtonVariant.outline:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.primary,
          border: AppColors.primary,
        );
      case JunaButtonVariant.ghost:
        return _ButtonColors(
          background: AppColors.primarySurface,
          foreground: AppColors.primary,
        );
      case JunaButtonVariant.danger:
        return _ButtonColors(
          background: Colors.transparent,
          foreground: AppColors.error,
          border: AppColors.error,
        );
    }
  }
}

class _ButtonColors {
  final Color background;
  final Color foreground;
  final Color? border;
  _ButtonColors({required this.background, required this.foreground, this.border});
}
