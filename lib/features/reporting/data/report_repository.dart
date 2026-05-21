import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/report_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import 'mock_reporting_data.dart';

class ReportRepository {
  final Dio _dio;
  
  /// Toggle this to switch between Mock and Real API data
  static const bool useMockData = false;

  ReportRepository(DioClient dioClient) : _dio = dioClient.dio;

  /// Fetch all reports for the city feed
  Future<List<ReportModel>> fetchReports() async {
    if (useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));
      return MockReportingData.mockCityFeed;
    }
    
    try {
      final response = await _dio.get(ApiConstants.reports);
      final List<dynamic> data = response.data;
      return data.map((json) => _mapJsonToReport(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch reports submitted by current user
  Future<List<ReportModel>> fetchMyReports() async {
    if (useMockData) {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 600));
      return MockReportingData.mockMyActivity;
    }

    try {
      final response = await _dio.get(ApiConstants.myReports);
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
    String? locationName,
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
        'location_name': locationName,
        'photos[]': multiparts,
      });

      final response = await _dio.post(ApiConstants.reports, data: formData);
      return _mapJsonToReport(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch a single report by ID
  Future<ReportModel> fetchReportById(String reportId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 400));
      final all = [...MockReportingData.mockCityFeed, ...MockReportingData.mockMyActivity];
      return all.firstWhere((r) => r.id == reportId, orElse: () => MockReportingData.mockCityFeed.first);
    }

    final url = ApiConstants.reportDetail.replaceAll('{id}', reportId);
    final response = await _dio.get(url);
    return _mapJsonToReport(response.data as Map<String, dynamic>);
  }

  /// Upvote a report
  Future<void> upvote(String reportId) async {
    try {
      final url = ApiConstants.reportVotes.replaceAll('{id}', reportId);
      await _dio.post(url);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch available categories
  Future<List<dynamic>> fetchCategories() async {
    final prefs = await SharedPreferences.getInstance();
    const String cacheKey = 'cached_report_categories';
    try {
      final response = await _dio.get(ApiConstants.categories);
      final list = response.data as List<dynamic>;
      await prefs.setString(cacheKey, jsonEncode(list));
      return list;
    } catch (e) {
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        try {
          return jsonDecode(cached) as List<dynamic>;
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Map JSON from Laravel API to our Flutter ReportModel
  ReportModel _mapJsonToReport(Map<String, dynamic> json) {
    // Extract images — prefer the full image_url the API now appends,
    // fall back to building the URL from image_path manually.
    const String storageBase = 'https://cleancity-api.onrender.com/storage/';
    final List<dynamic> imagesJson = json['images'] ?? [];
    final List<String> imageUrls = imagesJson
        .map((img) {
          // API now appends image_url; image_path is the fallback
          final url  = img['image_url']  as String? ?? '';
          final path = img['image_path'] as String? ?? '';
          if (url.isNotEmpty)  return url;
          if (path.startsWith('http')) return path;
          if (path.isNotEmpty) return '$storageBase$path';
          return '';
        })
        .where((u) => u.isNotEmpty)
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
      userId: json['user_id']?.toString(),
      category: categoryData['name'] ?? 'Unknown',
      categoryIcon: categoryData['icon'],
      categoryColor: categoryData['color'],
      images: imageUrls,
      description: json['description'] ?? '',
      location: json['location_name'] ?? json['title'] ?? 'Unknown Location',
      locationName: json['location_name'],
      date: DateTime.parse(json['created_at']),
      status: json['status'],
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      upvotes: json['upvotes_count'] ?? 0,
      priorityScore: json['priority_score'] ?? 0,
      hasVoted: json['user_has_voted'] == true,
      statusHistory: history,
    );
  }
}
