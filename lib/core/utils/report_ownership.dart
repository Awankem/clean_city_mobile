import '../../features/reporting/domain/report_model.dart';

bool isOwnReport(ReportModel report, String? currentUserId) {
  if (report.userId == null || currentUserId == null) return false;
  return report.userId == currentUserId;
}

bool canUpvoteReport(ReportModel report, String? currentUserId) {
  return !isOwnReport(report, currentUserId) && !report.hasVoted;
}
