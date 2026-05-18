import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class AuthRepository {
  final Dio _dio;

  AuthRepository(DioClient dioClient) : _dio = dioClient.dio;

  Future<void> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['token'] ?? response.data['access_token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
      } else {
        throw Exception("No token received from backend");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String name, String email, String phone, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'password_confirmation': password,
        },
      );

      final token = response.data['token'] ?? response.data['access_token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
      } else {
        throw Exception("No token received from backend");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (e) {
      // Ignore errors on logout
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    }
  }

  Future<Map<String, dynamic>> getUser() async {
    try {
      final response = await _dio.get(ApiConstants.user);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
