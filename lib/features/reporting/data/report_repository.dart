import 'package:dio/dio.dart';
import '../domain/report_model.dart';
import '../../../core/network/dio_client.dart';

class ReportRepository {
  final Dio _dio;

  ReportRepository(DioClient dioClient) : _dio = dioClient.dio;

  /// Fetch all reports for the city feed
  Future<List<ReportModel>> fetchReports() async {
    try {
      final response = await _dio.get('/reports');
      final List<dynamic> data = response.data;
      return data.map((json) => _mapJsonToReport(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch reports submitted by current user
  Future<List<ReportModel>> fetchMyReports() async {
    try {
      final response = await _dio.get('/my-reports');
      final List<dynamic> data = response.data;
      return data.map((json) => _mapJsonToReport(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Submit a new report with multiple images
  Future<ReportModel> submitReport({
    required int categoryId,
    required String description,
    required double latitude,
    required double longitude,
    required List<String> imagePaths,
  }) async {
    try {
      final List<MultipartFile> multiparts = [];
      for (var path in imagePaths) {
        multiparts.add(await MultipartFile.fromFile(path, filename: path.split('/').last));
      }

      final formData = FormData.fromMap({
        'category_id': categoryId,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'photos[]': multiparts,
      });

      final response = await _dio.post('/reports', data: formData);
      return _mapJsonToReport(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Map JSON from Laravel API to our Flutter ReportModel
  ReportModel _mapJsonToReport(Map<String, dynamic> json) {
    // Extract images from related images table
    final List<dynamic> imagesJson = json['images'] ?? [];
    final List<String> imageUrls = imagesJson
        .map((img) => img['image_url'] as String) // Assuming your API returns full URLs
        .toList();

    // Extract status history
    final List<dynamic> historyJson = json['status_history'] ?? [];
    final List<StatusHistoryModel> history = historyJson
        .map((h) => StatusHistoryModel.fromJson(h))
        .toList();

    // Map the category attributes driven by the backend
    final categoryData = json['category'] ?? {};

    return ReportModel(
      id: json['id'].toString(),
      category: categoryData['name'] ?? 'Unknown',
      categoryIcon: categoryData['icon'],
      categoryColor: categoryData['color'],
      images: imageUrls,
      description: json['description'] ?? '',
      location: json['location_name'] ?? 'Unknown Location', // Laravel stores this
      date: DateTime.parse(json['created_at']),
      status: json['status'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      upvotes: json['upvotes_count'] ?? 0,
      priorityScore: json['priority_score'] ?? 0,
      statusHistory: history,
    );
  }
}
