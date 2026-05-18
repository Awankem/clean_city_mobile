class ApiConstants {
  static const String baseUrl = 'https://cleancity-api.onrender.com/api'; // Live Render Backend
  
  // Auth Endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String user = '/user';
  
  // Reports
  static const String reports = '/reports';
  static const String myReports = '/my-reports';
  static const String categories = '/categories';
  static const String reportVotes = '/reports/{id}/upvote';
  
  // Receive timeouts
  static const int receiveTimeout = 15000;
  static const int connectionTimeout = 15000;
}
