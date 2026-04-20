class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Standard Android Emulator local IP
  
  // Auth Endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  
  // Reports
  static const String reports = '/reports';
  static const String myReports = '/reports/my';
  static const String categories = '/categories';
  static const String reportVotes = '/reports/{id}/vote';
  
  // Receive timeouts
  static const int receiveTimeout = 15000;
  static const int connectionTimeout = 15000;
}
