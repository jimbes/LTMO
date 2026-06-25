class ApiConfig {
  // Development (Android Emulator uses 10.0.2.2 for host localhost)
  static const String devBaseUrl = 'http://10.0.2.2:8000/api/v1';

  // Production
  static const String prodBaseUrl = 'https://pma.besse.dev/api/v1';

  // Switch to production
  static String get baseUrl => prodBaseUrl;

  // Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authMe = '/auth/me';
  static const String authLogout = '/auth/logout';
  static const String authInvitePartner = '/auth/invite-partner';
  static const String authAcceptInvite = '/auth/accept-invite';

  static const String appointments = '/appointments';
  static const String medications = '/medications';
  static const String medicationSchedules = '/medication-schedules';
  static const String medicationLogs = '/medication-taken-logs';
  static const String deviceTokens = '/device-tokens';
  static const String partner = '/partner';
  static const String notifications = '/notifications';

  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
