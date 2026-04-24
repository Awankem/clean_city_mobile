class StatusHistoryModel {
  final String status;
  final String? note;
  final DateTime createdAt;
  final String? changedBy;

  StatusHistoryModel({
    required this.status,
    this.note,
    required this.createdAt,
    this.changedBy,
  });

  factory StatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return StatusHistoryModel(
      status: json['new_status'] ?? '',
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      changedBy: json['changed_by']?.toString(), // Simplified for now
    );
  }
}

class ReportModel {
  final String id;
  final String category;
  final String? categoryIcon; // Dynamic icon from backend
  final String? categoryColor; // Dynamic color from backend
  final List<String> images;
  final String description;
  final String location;
  final DateTime date;
  final String status;
  final double latitude;
  final double longitude;
  final int upvotes;
  final int priorityScore;
  final List<StatusHistoryModel> statusHistory;

  ReportModel({
    required this.id,
    required this.category,
    this.categoryIcon,
    this.categoryColor,
    required this.images,
    required this.description,
    required this.location,
    required this.date,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.upvotes = 0,
    this.priorityScore = 0,
    this.statusHistory = const [],
  });
}

