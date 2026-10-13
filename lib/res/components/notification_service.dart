import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../main.dart';
import 'api_service.dart';

class NotificationService extends GetxService {
  static RemoteMessage? initialMessage;
  NotificationService();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future<String?> _getFcmTokenSafely() async {
    try {
      if (Platform.isIOS) {
        String? apnsToken = await messaging.getAPNSToken();
        int retries = 0;
        while (apnsToken == null && retries < 10) {
          debugPrint('Waiting for APNS token... Attempt $retries');
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await messaging.getAPNSToken();
          retries++;
        }
        if (apnsToken == null) {
          debugPrint('APNS token could not be retrieved. FCM token might fail.');
          return null;
        }
      }
      return await messaging.getToken();
    } catch (e, stackTrace) {
      debugPrint('Error fetching FCM token safely: $e\n$stackTrace');
      return null;
    }
  }

  Future<String> getDeviceToken() async {
    String? token = await _getFcmTokenSafely();
    debugPrint('DEVICE token :::::::::::::::::::::::::::    $token');
    return token ?? '';
  }

  static Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      debugPrint('Notification permission granted');
    } else if (status.isDenied) {
      debugPrint('Notification permission denied.');
    } else if (status.isPermanentlyDenied) {
      debugPrint('Notification permission permanently denied. Open settings.');
      openAppSettings();
    }
  }

  NotificationService._();
  static final NotificationService instance = NotificationService._();
  @override
  void onReady() {
    super.onReady();

    if (NotificationService.initialMessage != null) {
      final msg = NotificationService.initialMessage!;
      NotificationService.instance._handleMessage(msg);

      NotificationService.initialMessage = null;
    }
  }

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _storage = const FlutterSecureStorage();
  bool _isLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _requestPermission();

      await setupLocalNotifications();

      await _setupMessageHandlers();

      await Future.delayed(const Duration(milliseconds: 1000));
      debugPrint(
        'Delayed FCM registration to ensure ApiService availability at ${DateTime.now()}',
      );
      await _registerFcmToken();

      _messaging.onTokenRefresh.listen((newToken) async {
        debugPrint('FCM token refreshed: $newToken');
        _storage.write(key: 'fcm_token', value: newToken);
        await _registerFcmToken(fcmToken: newToken);
      });
    } catch (e, stackTrace) {
      debugPrint('NotificationService initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );
      debugPrint(
        'Notification permission status: ${settings.authorizationStatus}',
      );
    } catch (e, stackTrace) {
      debugPrint('Error requesting notification permissions: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _registerFcmToken({String? fcmToken}) async {
    try {
      final token = fcmToken ?? await _getFcmTokenSafely();
      if (token == null || token.isEmpty) {
        debugPrint('FCM token is null or empty');
        return;
      }
      debugPrint('FCM token: $token');

      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) {
        debugPrint('Access token not found');
        return;
      }

      ApiService? apiService;
      for (int attempt = 1; attempt <= 3; attempt++) {
        if (Get.isRegistered<ApiService>()) {
          apiService = Get.find<ApiService>();
          debugPrint(
            'ApiService found on attempt $attempt at ${DateTime.now()}',
          );
          break;
        }
        debugPrint(
          'ApiService not found on attempt $attempt. Retrying after 500ms...',
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (apiService == null) {
        debugPrint(
          'ApiService not found after 3 attempts. Ensure Get.put(ApiService()) is called in main.dart',
        );
        return;
      }

      final response = await apiService.registerFcmToken(
        accessToken: accessToken,
        fcmToken: token,
      );

      if (response['statusCode'] == 200 || response['statusCode'] == 201) {
        debugPrint('FCM token registered: $token');
      } else {
        debugPrint(
          'FCM token registration failed: ${response['data']['detail'] ?? response['data']['message'] ?? 'Status code ${response['statusCode']}'}',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error registering FCM token: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> setupLocalNotifications() async {
    if (_isLocalNotificationsInitialized) return;

    try {
      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Used for important notifications.',
        importance: Importance.high,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.createNotificationChannel(channel);

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload != null) {
            _handleNotificationTap(response.payload!);
          }
        },
      );

      _isLocalNotificationsInitialized = true;
      debugPrint('Local notifications initialized');
    } catch (e, stackTrace) {
      debugPrint('Error setting up local notifications: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> showNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final android = message.notification?.android;
      if (notification == null || android == null) {
        debugPrint('No notification or Android-specific data found');
        return;
      }

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Used for important notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@drawable/ic_stat_notify',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
      debugPrint('Notification shown: ${notification.title}');
    } catch (e, stackTrace) {
      debugPrint('Error showing notification: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _setupMessageHandlers() async {
    try {
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('Foreground message received: ${message.data}');
        showNotification(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        debugPrint('Message opened app: ${message.data}');
        _handleMessage(message);
      });

      _messaging.getInitialMessage().then((initialMessage) {
        if (initialMessage != null) {
          debugPrint('Initial message: ${initialMessage.data}');
          _handleMessage(initialMessage);
        }
      }).catchError((e) {
        debugPrint('Error getting initial message: $e');
      });
    } catch (e, stackTrace) {
      debugPrint('Error setting up message handlers: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type']?.toString();
    debugPrint('Handling message type: $type');

    switch (type) {
      case 'profile':
        _handleProfileNotification(data);
        break;
      default:
        debugPrint('Unknown notification type: $type');
    }
  }

  void _handleProfileNotification(Map<String, dynamic> data) {
    try {
      final profileId = data['profileId']?.toString();
      if (profileId != null) {
        debugPrint('Navigated to profile: $profileId');
      } else {
        debugPrint('Invalid profile notification: missing profileId');
      }
    } catch (e, stackTrace) {
      debugPrint('Error handling profile notification: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  void _handleNotificationTap(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      debugPrint('Notification tapped with payload: $payload');
      _handleMessage(RemoteMessage(data: data));
    } catch (e, stackTrace) {
      debugPrint('Error parsing notification tap payload: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
