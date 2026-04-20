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

// Global list of mock reports for the UI development (updated for compatibility)
final List<ReportModel> mockReports = [
  ReportModel(
    id: '1',
    category: 'Overflowing Bin',
    categoryIcon: 'delete_sweep',
    categoryColor: '#81C784',
    images: [
      'https://images.unsplash.com/photo-1605600611284-19561ad7ddf0?q=80&w=600',
      'https://images.unsplash.com/photo-1595273670150-db0a3d39dbd3?q=80&w=600',
    ],
    description: 'The industrial bin at North Station has been overflowing for 3 days.',
    location: 'North Station Avenue, Bamenda',
    date: DateTime.now().subtract(const Duration(hours: 5)),
    status: 'pending',
    latitude: 5.9631,
    longitude: 10.1591,
    upvotes: 12,
    priorityScore: 45,
    statusHistory: [
      StatusHistoryModel(
        status: 'pending',
        note: 'Report registered.',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ],
  ),
  ReportModel(
    id: '2',
    category: 'Illegal Dumping',
    categoryIcon: 'warning_amber',
    categoryColor: '#FFB74D',
    images: [
      'https://images.unsplash.com/photo-1595273670150-db0a3d39dbd3?q=80&w=600',
    ],
    description: 'Large pile of construction debris dumped behind the old council building.',
    location: 'Old Council Area',
    date: DateTime.now().subtract(const Duration(days: 1)),
    status: 'in_progress',
    latitude: 5.9599,
    longitude: 10.1601,
    upvotes: 8,
    priorityScore: 32,
    statusHistory: [
      StatusHistoryModel(
        status: 'pending',
        note: 'Report registered.',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      ),
      StatusHistoryModel(
        status: 'in_progress',
        note: 'Sanitation team dispatched.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  ),
];

