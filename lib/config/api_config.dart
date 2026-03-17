import 'package:shared_preferences/shared_preferences.dart';

/// api_config.dart — جميع نقاط API
class ApiConfig {
  static String _serverIp = '192.168.1.20';
  static String get _host => 'http://$_serverIp/Trusted-Social-Network-Platform/api/v1';

  static Future<void> loadHost() async {
    final prefs = await SharedPreferences.getInstance();
    _serverIp = prefs.getString('server_ip') ?? '192.168.1.20';
  }

  static Future<void> setHost(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
    _serverIp = ip;
  }

  static String get serverIp => _serverIp;

  // Auth
  static String get login      => '$_host/auth/login.php';
  static String get verifyOtp   => '$_host/auth/verify_otp.php';
  static String get resendOtp   => '$_host/auth/resend_otp.php';
  static String get register    => '$_host/auth/register.php';

  // Content
  static String get feed         => '$_host/feed.php';
  static String get posts        => '$_host/posts.php';
  static String get groups       => '$_host/groups.php';
  static String get messages     => '$_host/messages.php';
  static String get users        => '$_host/users.php';
  static String get notifications => '$_host/notifications.php';
  static String get fcmToken     => '$_host/fcm_token.php';
  static String get profile      => '$_host/profile.php';
  static String get files        => '$_host/files.php';
  static String get calendar     => '$_host/calendar.php';
  static String get reports      => '$_host/reports.php';
  static String get support      => '$_host/support.php';
  static String get search       => '$_host/search.php';
  static String get groupsManage => '$_host/groups_manage.php';
}
