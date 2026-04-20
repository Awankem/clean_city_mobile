import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import 'report_repository.dart';
import '../domain/report_model.dart';

/// Provider for the DioClient
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

/// Provider for the ReportRepository
final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return ReportRepository(dioClient);
});

/// Provider for the Public City Feed reports
final cityReportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  return repository.fetchReports();
});

/// Provider for the Current User's reports (My Activity)
final myReportsProvider = FutureProvider<List<ReportModel>>((ref) async {
  final repository = ref.watch(reportRepositoryProvider);
  return repository.fetchMyReports();
});
