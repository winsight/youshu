import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/l10n/app_locale.dart';

class DailyCostProgressBar extends StatelessWidget {
  final double progressRatio;
  final int daysLeft;
  final bool goalAchieved;

  const DailyCostProgressBar({
    super.key,
    required this.progressRatio,
    required this.daysLeft,
    this.goalAchieved = false,
  });

  @override
  Widget build(BuildContext context) {
    final clampedRatio = progressRatio.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 8,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              return Stack(
                children: [
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: clampedRatio,
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  if (clampedRatio < 1.0)
                    Positioned(
                      left: barWidth * clampedRatio - 4,
                      top: -2,
                      child: Container(
                        width: 0,
                        height: 0,
                        decoration: const BoxDecoration(
                          border: Border(
                            left: BorderSide(
                                width: 4, color: Colors.transparent),
                            right: BorderSide(
                                width: 4, color: Colors.transparent),
                            top: BorderSide(
                                width: 6, color: AppColors.onSurface),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          goalAchieved
              ? AppL10n.of(context).goalAchieved
              : '$daysLeft ${AppL10n.of(context).daysLeft}',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 9,
            color: goalAchieved ? AppColors.primary : AppColors.onSurfaceVariant,
            fontWeight: goalAchieved ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class SegmentedProgressBar extends StatelessWidget {
  final double progressRatio;
  final int segments;

  const SegmentedProgressBar({
    super.key,
    required this.progressRatio,
    this.segments = 6,
  });

  @override
  Widget build(BuildContext context) {
    final filledSegments = (progressRatio * segments).round().clamp(0, segments);

    return Row(
      children: List.generate(
        segments,
        (i) => Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(left: i > 0 ? 2 : 0),
            decoration: BoxDecoration(
              color: i < filledSegments
                  ? i < filledSegments - 1
                      ? AppColors.primary
                      : AppColors.primary.withAlpha(100)
                  : AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.horizontal(
                left: i == 0 ? const Radius.circular(4) : Radius.zero,
                right: i == segments - 1
                    ? const Radius.circular(4)
                    : Radius.zero,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
