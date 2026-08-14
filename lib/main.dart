import 'package:dabadacademy/Screens/AttendanceScreen.dart';
import 'package:dabadacademy/Screens/DocumentEditScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'FCM.dart';
import 'firebase_options.dart'; // Import the generated firebase options
import 'Screens/FeeStatusScreen.dart';
import 'Screens/ProfileScreen.dart';
import 'Screens/HomeScreen.dart';
import 'Screens/NoticeScreen.dart';
import 'Screens/SignInScreen.dart';
import 'Screens/TestResultScreen.dart';
import 'Screens/SplashScreen.dart';

// Global navigation key for navigating from outside of context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Define a top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background handlers
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling a background message: ${message.messageId}");
  print("Message data: ${message.data}");
}

// Create a notification channel for Android
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'This channel is used for important notifications.',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
);

// Initialize the local notifications plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Global authenticated user ID, populated during splash screen initialization
int? globalUserId;

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI mode
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  // Initialize Firebase before setting background handler or running app
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization error in main: $e');
  }

  runApp(const StudentManagementApp());
}

Future<void> initLocalNotifications() async {
  // Android initialization settings
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('launcher_icon');

  // iOS initialization settings
  const DarwinInitializationSettings initializationSettingsIOS =
  DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  // Combined initialization settings
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  // Initialize the plugin
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      print('Notification clicked with payload: ${response.payload}');
      // Navigate based on payload
      if (response.payload != null) {
        navigatorKey.currentState?.pushNamed(response.payload!);
      }
    },
  );
}

void setupMessageHandling() {
  // Handle messages when the app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@drawable/ic_notification',  // Use asset path
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: message.data['route'] ?? '/home',
      );
    }
  });

  // Handle notification clicks when app is in background but opened
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A notification was clicked with app in background!');
    print('Message data: ${message.data}');

    // Navigate based on the route in the payload
    if (message.data.containsKey('route')) {
      final String route = message.data['route'];
      navigatorKey.currentState?.pushNamed(route);
    }
  });
}

// Optional: Method to send a sample notification (can be used for testing)
void sendSampleNotification() {
  final fcmService = FCMService();
  fcmService.sendCustomNotification(
      title: 'Hello',
      body: 'This is a test notification',
      data: {
        'route': '/home',
        'key': 'value'
      }
  );
}

class StudentManagementApp extends StatelessWidget {
  const StudentManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Use the global navigation key
      theme: ThemeData(
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/signin': (context) => const SignInScreen(),
        '/home': (context) => HomeScreen(userId: globalUserId ?? 0),
        '/attendance': (context) => AttendanceScreen(userId: globalUserId ?? 0),
        '/notice': (context) => NoticeScreen(userId: globalUserId ?? 0),
        '/profile': (context) => ProfileScreen(userId: globalUserId ?? 0),
        '/feeStatus': (context) => FeeStatusScreen(userId: globalUserId ?? 0),
        '/testRecord': (context) => TestResultScreen(userId: globalUserId ?? 0),
      },
    );
  }
}