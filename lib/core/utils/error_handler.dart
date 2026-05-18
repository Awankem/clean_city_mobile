import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ErrorHandler {
  /// Parses the exception and extracts a user-friendly message
  static String getMessage(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout || 
          error.type == DioExceptionType.receiveTimeout || 
          error.type == DioExceptionType.sendTimeout) {
        return "Connection timed out. Please check your internet connection and try again.";
      }
      
      if (error.type == DioExceptionType.connectionError || error.type == DioExceptionType.unknown) {
        return "Unable to connect to the server. Please check your internet connection.";
      }

      if (error.response != null) {
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          // Check for Laravel validation errors
          if (data.containsKey('errors')) {
            final errors = data['errors'] as Map<String, dynamic>;
            // Return the first validation error message
            return errors.values.first.first.toString();
          }
          // Check for standard message
          if (data.containsKey('message')) {
            return data['message'].toString();
          }
        }
        
        if (error.response?.statusCode == 401) {
          return "Invalid email or password.";
        }
        if (error.response?.statusCode == 500) {
          return "Something went wrong on our server. Please try again later.";
        }
        
        return "Server error: ${error.response?.statusCode}";
      }
    }
    
    // For standard exceptions
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }

    return "An unexpected error occurred.";
  }

  /// Displays a beautiful, modern error popup
  static void showErrorPopup(BuildContext context, dynamic error) {
    final message = getMessage(error);
    
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: Colors.red, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Oops!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.onSurface.withOpacity(0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
