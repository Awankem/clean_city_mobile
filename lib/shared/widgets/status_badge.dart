import 'package:flutter/material.dart';
import '../../core/utils/report_status_utils.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 10, vertical: 4),
      decoration: BoxDecoration(
        color: ReportStatusUtils.badgeBackground(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        ReportStatusUtils.badgeLabel(status, compact: compact),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: ReportStatusUtils.color(status),
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
