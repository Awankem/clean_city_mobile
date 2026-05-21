import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import '../constants/api_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  final Dio _dio;

  DioClient() : _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
    connectTimeout: const Duration(milliseconds: ApiConstants.connectionTimeout),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  )) {
    // Configure cache options
    final cacheOptions = CacheOptions(
      store: MemCacheStore(),
      policy: CachePolicy.request, // Request if cache expired, fallback to cache on network errors
      hitCacheOnErrorCodes: [500, 502, 503, 504],
      hitCacheOnNetworkFailure: true,
      maxStale: const Duration(days: 7),
      priority: CachePriority.normal,
    );

    // Add Cache Interceptor first
    _dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) {
        // Handle global error states (401, etc)
        if (e.response?.statusCode == 401) {
          // Triggers logout or token refresh
        }
        return handler.next(e);
      },
    ));
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  Dio get dio => _dio;
}
