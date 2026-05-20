/// Report ID formatting aligned with Laravel admin (`#CC-0042`).
class ReportFormatUtils {
  ReportFormatUtils._();

  static String reportId(String id) {
    final numeric = int.tryParse(id) ?? 0;
    return '#CC-${numeric.toString().padLeft(4, '0')}';
  }
}
