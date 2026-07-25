import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// Import your constants file

class FCMService {
  // Server API endpoint for token registration using your actual API
  static const String _baseUrl = 'http://ec2-13-202-53-68.ap-south-1.compute.amazonaws.com:3002/api';
  static const String _registerEndpoint = '$_baseUrl/register-device';
  static const String _unregisterEndpoint = '$_baseUrl/unregister-device';

  // Singleton pattern
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Notification channel
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  // Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Request permission on iOS and Android 13+
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Log FCM token for debugging (with 5-second timeout)
      String? token = await _firebaseMessaging.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('FCM token fetch timed out during initialize');
          return null;
        },
      );
      debugPrint('FCM Token: $token');

      // Listen for token refreshes
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        _registerTokenWithServer(newToken);
      });

      // Initialize notifications
      await _initializeNotifications();
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  // Initialize notification handling
  Future<void> _initializeNotifications() async {
    // Create Android notification channel
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Android initialization settings (uses app icon)
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('launcher_icon');

    // iOS initialization settings
    final DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );

    // Combined initialization settings
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Initialize the plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        _handleNotificationTap(details);
      },
    );

    // Setup notification handling
    _setupNotificationHandling();
  }

  // Configure notification handling
  void _setupNotificationHandling() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.notification?.title}');

      // Display notification
      if (message.notification != null) {
        _flutterLocalNotificationsPlugin.show(
          message.hashCode,
          message.notification?.title,
          message.notification?.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: '@drawable/ic_notification', // Full reference
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // Handle background message
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published');
      _handleNotificationTap(NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: message.data.toString(),
      ));
    });
  }

  // Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint('Handling a background message: ${message.messageId}');
    // You can add additional background message handling logic here
  }

  // Handle notification tap
  void _handleNotificationTap(NotificationResponse details) {
    debugPrint('Notification tapped: ${details.payload}');
    // Add navigation or action logic when notification is tapped
    // For example:
    // Navigator.of(context).push(MaterialPageRoute(
    //   builder: (context) => SpecificScreen(data: details.payload)
    // ));
  }

  // Register user token with server after login
  Future<bool> registerUserToken(int userId) async {
    try {
      String? token = await _firebaseMessaging.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('FCM token fetch timed out during registerUserToken');
          return null;
        },
      );
      if (token == null) {
        debugPrint('Unable to get FCM token');
        return false;
      }

      return await _registerTokenWithServer(token, userId: userId);
    } catch (e) {
      debugPrint('Error registering user token: $e');
      return false;
    }
  }

  // Register token with server
  Future<bool> _registerTokenWithServer(String token, {int? userId}) async {
    try {
      // Get user ID from shared preferences if not provided
      final int userIdToUse = userId ?? await _getUserId();

      if (userIdToUse <= 0) {
        debugPrint('Invalid user ID for token registration');
        return false;
      }

      // Prepare registration data
      final Map<String, dynamic> data = {
        'user_id': userIdToUse,
        'token': token,
        'device_type': defaultTargetPlatform.name.toLowerCase(), // 'android', 'ios', etc.
      };

      // Send registration request with timeout
      final response = await http.post(
        Uri.parse(_registerEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('FCM token registered successfully with server');
        return true;
      } else {
        debugPrint('Failed to register FCM token: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error in token registration: $e');
      return false;
    }
  }

  // Unregister token when user logs out
  Future<bool> unregisterToken() async {
    try {
      String? token = await _firebaseMessaging.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('FCM token fetch timed out during unregisterToken');
          return null;
        },
      );
      if (token == null) {
        debugPrint('No FCM token to unregister');
        return false;
      }

      final response = await http.delete(
        Uri.parse(_unregisterEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        debugPrint('FCM token unregistered successfully');
        return true;
      } else {
        debugPrint('Failed to unregister FCM token: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error unregistering token: $e');
      return false;
    }
  }

  // Method to send a custom notification
  Future<void> sendCustomNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // You might want to use your server's send notification endpoint (with timeout)
      final response = await http.post(
        Uri.parse('$_baseUrl/send-notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        debugPrint('Custom notification sent successfully');
      } else {
        debugPrint('Failed to send custom notification: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending custom notification: $e');
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Subscription to topic $topic timed out');
        },
      );
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('Unsubscription from topic $topic timed out');
        },
      );
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  // Get user ID from shared preferences
  Future<int> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id') ?? 0;
  }
}

// Usage in app initialization
void setupNotifications() async {
  // Assuming FCMService is a singleton
  final fcmService = FCMService();

  // Initialize Firebase Messaging
  await fcmService.initialize();
}