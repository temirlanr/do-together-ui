import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logger/logger.dart';
import '../../data/api/device_api.dart';
import '../../data/dto/dtos.dart';
import '../../data/dto/enums.dart';

/// Background message handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages here if needed.
}

/// Service for FCM / APNs push notification token management.
///
/// ── Setup (required to receive real push notifications) ─────────────────
/// 1. Go to https://console.firebase.google.com → create/open your project.
/// 2. Add an Android app with package name: com.example.do_together
///    → Download google-services.json → replace android/app/google-services.json
/// 3. (iOS) Add an iOS app → download GoogleService-Info.plist → ios/Runner/
/// 4. Firebase Console → Project Settings → Cloud Messaging → add APNs key/cert.
/// 5. Rebuild the app.  Token will appear in Settings after that.
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._();
  factory PushNotificationService() => _instance;
  PushNotificationService._();

  final Logger _log = Logger();
  bool _initialised = false;
  String? _token;

  String? get currentToken => _token;

  /// Initialise Firebase and request permissions (iOS).
  /// Returns false when Firebase is not properly configured.
  Future<bool> initialise() async {
    if (_initialised) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      if (Platform.isIOS) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      _initialised = true;
      return true;
    } catch (e) {
      _log.w('Firebase not configured — push notifications unavailable: $e');
      return false;
    }
  }

  /// Returns the FCM / APNs device token, or null if Firebase is not set up.
  Future<String?> getToken() async {
    final ok = await initialise();
    if (!ok) return null;
    try {
      _token = await FirebaseMessaging.instance.getToken();
      _log.i('FCM token: $_token');
      return _token;
    } catch (e) {
      _log.w('Could not get FCM token: $e');
      return null;
    }
  }

  /// Register this device with the DoTogether backend.
  Future<bool> registerWithBackend(DeviceApi api) async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final platform = Platform.isIOS ? PushPlatform.apns : PushPlatform.fcm;
      await api
          .registerDevice(RegisterDeviceDto(platform: platform, token: token));
      _log.i('Device registered for push notifications');
      return true;
    } catch (e) {
      _log.e('Device registration failed: $e');
      return false;
    }
  }

  /// Unregister this device from the backend.
  Future<void> unregisterFromBackend(DeviceApi api) async {
    final token = _token;
    if (token == null) return;
    try {
      final platform = Platform.isIOS ? PushPlatform.apns : PushPlatform.fcm;
      await api.unregisterDevice(
          RegisterDeviceDto(platform: platform, token: token));
      _token = null;
    } catch (e) {
      _log.w('Device unregistration failed: $e');
    }
  }
}
