import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Status labels and colors aligned with Laravel admin `status-badge` component.
class ReportStatusUtils {
  ReportStatusUtils._();

  static String normalize(String status) => status.toLowerCase().trim();

  static String badgeLabel(String status, {bool compact = false}) {
    if (compact) return compactBadgeLabel(status);
    switch (normalize(status)) {
      case 'pending':
        return 'PENDING REVIEW';
      case 'in_progress':
        return 'IN REVIEW';
      case 'resolved':
        return 'RESOLVED';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  static String compactBadgeLabel(String status) {
    switch (normalize(status)) {
      case 'pending':
        return 'PENDING';
      case 'in_progress':
        return 'IN REVIEW';
      case 'resolved':
        return 'RESOLVED';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  static String displayLabel(String status) {
    switch (normalize(status)) {
      case 'pending':
        return 'Pending review';
      case 'in_progress':
        return 'In review';
      case 'resolved':
        return 'Resolved';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  /// Text color on status badge (Laravel on-* tokens).
  static Color color(String status) {
    switch (normalize(status)) {
      case 'pending':
        return Colors.white;
      case 'in_progress':
        return const Color(0xFF705400);
      case 'resolved':
        return Colors.white;
      default:
        return AppColors.onSurface;
    }
  }

  /// Badge background (Laravel *-container tokens).
  static Color badgeBackground(String status) {
    switch (normalize(status)) {
      case 'pending':
        return AppColors.tertiaryContainer;
      case 'in_progress':
        return AppColors.secondaryContainer;
      case 'resolved':
        return AppColors.primaryContainer;
      default:
        return AppColors.surfaceContainerHigh;
    }
  }

  static IconData icon(String status) {
    switch (normalize(status)) {
      case 'pending':
        return Icons.pending_actions_outlined;
      case 'in_progress':
        return Icons.moped_outlined;
      case 'resolved':
        return Icons.task_alt_outlined;
      default:
        return Icons.info_outline;
    }
  }

  /// Priority bar color thresholds (Laravel priority-bar.blade.php).
  static Color priorityColor(num score) {
    if (score > 7) return AppColors.tertiaryContainer;
    if (score > 4) return AppColors.secondaryContainer;
    return AppColors.primary;
  }
}
