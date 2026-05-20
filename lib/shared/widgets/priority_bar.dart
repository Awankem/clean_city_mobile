import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/report_status_utils.dart';

/// Horizontal priority bar matching Laravel `priority-bar` component.
class PriorityBar extends StatelessWidget {
  final num score;
  final double width;

  const PriorityBar({super.key, required this.score, this.width = 48});

  @override
  Widget build(BuildContext context) {
    final pct = (score * 10).clamp(0, 100).toDouble();
    final color = ReportStatusUtils.priorityColor(score);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: ColoredBox(
              color: AppColors.surfaceContainerHighest,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: pct / 100,
                  child: ColoredBox(color: color),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.onSurface,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
