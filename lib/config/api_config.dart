/// api_config.dart — جميع نقاط API
class ApiConfig {
  // ─── غيّر هذا لـ IP جهازك أو دومين السيرفر ───
  static const String _host =
      'http://192.168.1.20/Trusted-Social-Network-Platform/api/v1';
  // 10.0.2.2 = localhost من داخل Android Emulator
  // للجهاز الحقيقي: استخدم IP جهازك مثل http://192.168.x.x/...

  // Auth
  static const String login      = '$_host/auth/login.php';
  static const String verifyOtp   = '$_host/auth/verify_otp.php';
  static const String resendOtp   = '$_host/auth/resend_otp.php';
  static const String register    = '$_host/auth/register.php';

  // Content
  static const String feed         = '$_host/feed.php';
  static const String posts        = '$_host/posts.php';
  static const String groups       = '$_host/groups.php';
  static const String messages     = '$_host/messages.php';
  static const String notifications = '$_host/notifications.php';
  static const String fcmToken     = '$_host/fcm_token.php';
  static const String profile      = '$_host/profile.php';
  static const String files        = '$_host/files.php';
}
