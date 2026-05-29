import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class GradientHeader extends StatelessWidget {
  final Widget child;
  final double? height;

  const GradientHeader({super.key, required this.child, this.height});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topLeft,
          colors: [AppColors.primary.withAlpha(20), colors.surface],
        ),
      ),
      child: child,
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const GlassCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(DesignTokens.cardRadius),
          border: Border.all(color: colors.outlineVariant.withAlpha(80)),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withAlpha(
                colors.brightness == Brightness.dark ? 80 : 10,
              ),
              blurRadius: 40,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
