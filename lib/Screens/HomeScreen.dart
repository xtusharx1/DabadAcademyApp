import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../FCM.dart';
import '../constants.dart'; // Import the constants file
import 'package:shared_preferences/shared_preferences.dart';
import 'AttendanceScreen.dart';
import 'FeeStatusScreen.dart';
import 'NoticeScreen.dart';
import 'ProfileScreen.dart';
import 'TestResultScreen.dart';

class HomeScreen extends StatelessWidget {
  final int userId;

  // Coursera color palette
  final Color primaryColor = Color(0xFF2A73CC); // Coursera blue
  final Color secondaryColor = Color(0xFF4A90E2); // Lighter blue
  final Color accentColor = Color(0xFF0056D2); // Darker blue
  final Color lightBgColor = Color(0xFFF5F7FA); // Light background

  HomeScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchUserDetails(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: lightBgColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading your dashboard...',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: lightBgColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.grey[600],
                      size: 60,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Error Loading Data',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    onPressed: () => _refreshPage(context),
                  ),
                ],
              ),
            ),
          );
        } else if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: lightBgColor,
            body: Center(
              child: Text(
                'No user data found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ),
          );
        }

        final user = snapshot.data!['user'];
        String greeting = _getGreeting();

        return Scaffold(
          backgroundColor: lightBgColor,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                _buildHeader(context, user, greeting),

                SizedBox(height: 16),

                // Welcome Message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Student Dashboard',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                ),

                SizedBox(height: 6),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Access all student information and resources',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Grid Section - Now using Expanded to fill available space
                Expanded(
                  child: _buildGridSection(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, dynamic> user, String greeting) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.0),
          bottomRight: Radius.circular(24.0),
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24.0,
                backgroundColor: Colors.white,
                child: Text(
                  user['name'] != null && user['name'].toString().isNotEmpty
                      ? user['name'].toString().substring(0, 1).toUpperCase()
                      : 'U',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16.0),
                  ),
                  SizedBox(height: 4),
                  Text(
                    user['name'] ?? 'Student',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleLogout(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.2), Colors.white.withOpacity(0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.white,
                size: 18,
              ),

            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) {
    // Show loading indicator dialog with enhanced design
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button dismissing the dialog
          child: Dialog(
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 50,
                    width: 50,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      strokeWidth: 3,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "Signing Out...",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Please wait while we complete the sign out process",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Perform logout operation
    logout(context);
  }



  Widget _buildGridSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.25, // Adjusted for better fit
        ),
        children: <Widget>[
          _buildGridItem(
              context,
              'Profile',
              Icons.person,
                  () => ProfileScreen(userId: userId),
              Color(0xFF5A85E1),
              'Personal info'
          ),
          _buildGridItem(
              context,
              'Fee Records',
              Icons.account_balance_wallet,
                  () => FeeStatusScreen(userId: userId),
              Color(0xFF43A9B9),
              'Payments & dues'
          ),
          _buildGridItem(
              context,
              'Test Results',
              Icons.assessment,
                  () => TestResultScreen(userId: userId),
              Color(0xFF647EF5),
              'Academic performance'
          ),
          _buildGridItem(
              context,
              'Attendance',
              Icons.calendar_today,
                  () => AttendanceScreen(userId: userId),
              Color(0xFF56AB88),
              'Attendance records'
          ),
          _buildGridItem(
              context,
              'Notices',
              Icons.notifications,
                  () => NoticeScreen(userId: userId),
              Color(0xFFE4763B),
              'Announcements'
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
      BuildContext context,
      String title,
      IconData icon,
      Widget Function() screen,
      Color color,
      String description
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => screen()));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Future<Map<String, dynamic>> _fetchUserDetails(int userId) async {
    final response = await http.get(Uri.parse('$BASE_URL/users/user/$userId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user details');
    }
  }

  Future<void> _refreshData(BuildContext context) async {
    // Refresh the page by rebuilding the widget
    await _fetchUserDetails(userId);
    return Future.value();
  }

  void _refreshPage(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen(userId: userId)),
    );
  }

  Future<void> logout(BuildContext context) async {
    try {
      // Get the user ID before logging out
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int userId = prefs.getInt('user_id') ?? 0;

      if (userId > 0) {
        try {
          // Initialize FCM service
          final FCMService fcmService = FCMService();

          // Unsubscribe from notification topics
          await fcmService.unsubscribeFromTopic('user_$userId');
          await fcmService.unsubscribeFromTopic('all_users');

          // Unregister FCM token from server
          await fcmService.unregisterToken();

          print('FCM token unregistered and topics unsubscribed');
        } catch (e) {
          print('FCM unsubscribe error: $e');
          // Continue with logout even if FCM operations fail
        }
      }

      // Clear user data from shared preferences
      await prefs.clear();

      // Navigate back to login screen and clear navigation stack
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signin',
            (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');

      // Even if token unregistration fails, still proceed with logout
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (e) {
        print('Error clearing preferences: $e');
      }

      // Force navigation to login screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/signin',
            (route) => false,
      );
    }
  }
}