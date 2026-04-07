class ApiEndpoints {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String signup = '/auth/register';
  static const String logout = '/auth/logout';

  // Dashboard endpoints
  static const String dashboard = '/dashboard';
  static const String attendance = '/attendance';
  static const String leaves = '/leaves';
  static const String requests = '/requests';
  static const String holidays = '/holidays';

  // Mock endpoints (for testing)
  static const String mockLogin = '/posts/1';
  static const String mockSignup = '/posts';
  static const String mockDashboard = '/posts/1';
}
