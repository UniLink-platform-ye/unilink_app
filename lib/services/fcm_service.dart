import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:ui';
import 'api_service.dart';
import '../config/api_config.dart';

/// معالج الرسائل في الخلفية (top-level function)
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  // Flutter يتولى عرض الإشعار تلقائياً في الخلفية
}

class FcmService {
  static final _fcm        = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'unilink_channel';
  static const _channelName = 'UniLink Notifications';

  static Future<void> initialize() async {
    // ── 1. إذن الإشعارات ──────────────────────────────────
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

    // ── 2. Foreground display (iOS) ───────────────────────
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    // ── 3. الإشعارات المحلية (Android) ───────────────────
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotif.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _onLocalNotifTap,
    );

    // إنشاء channel
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId, _channelName,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ));

    // ── 4. Handlers ───────────────────────────────────────
    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onTap);
  }

  static bool _tokenRefreshRegistered = false;

  /// حفظ FCM token في السيرفر بعد تسجيل الدخول
  static Future<void> registerToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      await ApiService.post(ApiConfig.fcmToken, {
        'fcm_token': token,
        'device_type': 'android',
      });

      // تسجيل listener مرة واحدة فقط لمنع التكرار
      if (!_tokenRefreshRegistered) {
        _tokenRefreshRegistered = true;
        _fcm.onTokenRefresh.listen((newToken) {
          ApiService.post(ApiConfig.fcmToken, {
            'fcm_token': newToken,
            'device_type': 'android',
          });
        });
      }
    } catch (e) {
      // لا نوقف التطبيق إذا فشل التسجيل
    }
  }

  /// إعادة تهيئة الحالة عند تسجيل الخروج
  static void resetState() {
    _tokenRefreshRegistered = false;
  }

  /// حذف FCM token عند تسجيل الخروج
  static Future<void> unregisterToken() async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await ApiService.delete(ApiConfig.fcmToken, body: {'fcm_token': token});
      await _fcm.deleteToken();
    } catch (_) {}
  }

  // ── Message Handlers ──────────────────────────────────────
  static Future<void> _onForeground(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notif.title ?? 'UniLink',
      notif.body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId, _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF2563EB),
        ),
      ),
      payload: message.data['link'],
    );
  }

  static void _onTap(RemoteMessage message) {
    // TODO: يمكنك إضافة navigation هنا
  }

  static void _onLocalNotifTap(NotificationResponse response) {
    // TODO: navigate based on response.payload (link)
  }
}
