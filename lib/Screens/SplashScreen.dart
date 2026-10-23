import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../FCM.dart';
import '../firebase_options.dart';
import '../constants.dart';
import '../main.dart';
import 'HomeScreen.dart';
import 'SignInScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  String _statusMessage = 'Starting up...';
  bool _showErrorState = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    int? userId;
    bool isInitializationFailed = false;

    // We set a maximum global timeout of 10 seconds. If initialization takes longer,
    // we proceed to the main app anyway so we never hang the app indefinitely.
    final globalTimeout = Future.delayed(const Duration(seconds: 10), () {
      debugPrint('Global startup initialization timeout reached!');
      return 'timeout';
    });

    final initProcess = Future<String>(() async {
      // 1. Initialize Firebase Core
      try {
        setState(() => _statusMessage = 'Connecting to Firebase...');
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 4));
      } catch (e) {
        debugPrint('Firebase initialization failed/timed out: $e');
        isInitializationFailed = true;
      }

      // 2. Request Notification Permissions
      try {
        setState(() => _statusMessage = 'Requesting permissions...');
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        ).timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Notification permissions request failed: $e');
      }

      // 3. Android notification channel creation
      try {
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel)
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Failed to create notification channel: $e');
      }

      // 4. Foreground notification options
      try {
        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        ).timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Failed to set foreground notification options: $e');
      }

      // 5. Initialize Local Notifications Plugin
      try {
        setState(() => _statusMessage = 'Setting up local notifications...');
        await initLocalNotifications().timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('Local notifications initialization failed: $e');
      }

      // 6. Initialize FCM Service
      try {
        final fcmService = FCMService();
        await fcmService.initialize().timeout(const Duration(seconds: 3));
      } catch (e) {
        debugPrint('FCMService initialization failed: $e');
      }

      // 7. Setup Message Handling
      try {
        setupMessageHandling();
      } catch (e) {
        debugPrint('Message handling setup failed: $e');
      }

      // 8. SharedPreferences (Critical for login state)
      try {
        setState(() => _statusMessage = 'Restoring session...');
        SharedPreferences prefs = await SharedPreferences.getInstance().timeout(
          const Duration(seconds: 3),
        );
        // Sessions saved before the login fallback fix may point to the wrong
        // account (iOS users were silently logged in as user 146), so force re-login once.
        if (prefs.getInt('session_version') != kSessionVersion) {
          await prefs.remove('user_id');
        }
        userId = prefs.getInt('user_id');
        globalUserId = userId; // Store globally for route builders
      } catch (e) {
        debugPrint('SharedPreferences session retrieval failed: $e');
        isInitializationFailed = true;
      }

      // 9. Subscribe to User Topic (Non-blocking)
      if (userId != null && userId! > 0) {
        try {
          setState(() => _statusMessage = 'Subscribing to updates...');
          final fcmService = FCMService();
          await fcmService.subscribeToTopic(userId.toString()).timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              debugPrint('FCM topic subscription timed out');
            },
          );
        } catch (e) {
          debugPrint('Failed to subscribe to user topic: $e');
        }
      }
      return 'success';
    });

    // Race the initialization against the global timeout
    final result = await Future.any([initProcess, globalTimeout]);

    if (result == 'timeout' && isInitializationFailed) {
      // If we timed out and core stuff failed, show a retry screen.
      setState(() {
        _statusMessage = 'Startup initialization taking longer than expected.';
        _showErrorState = true;
      });
    } else {
      // Proceed to the main flow
      _navigateToNextScreen(userId);
    }
  }

  void _navigateToNextScreen(int? userId) {
    if (!mounted) return;

    if (userId != null && userId > 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(userId: userId)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Coursera/Premium Theme Colors
    const primaryColor = Color(0xFF2A73CC); // Premium Blue
    const darkBgColor = Color(0xFF1E3A8A); // Deep Navy

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkBgColor, primaryColor],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo placeholder or image
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/icon.jpeg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.school_rounded,
                                size: 60,
                                color: primaryColor,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Dabad Academy',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Student Management Portal',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 64.0, left: 32.0, right: 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_showErrorState) ...[
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                      ] else ...[
                        Text(
                          _statusMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showErrorState = false;
                                  _statusMessage = 'Retrying...';
                                });
                                _initializeApp();
                              },
                              icon: const Icon(Icons.refresh_rounded, color: primaryColor),
                              label: const Text(
                                'Retry',
                                style: TextStyle(color: primaryColor),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            TextButton.icon(
                              onPressed: () => _navigateToNextScreen(null),
                              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                              label: const Text(
                                'Proceed Offline',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
