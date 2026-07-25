import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AttendanceScreen extends StatefulWidget {
  final int userId;

  const AttendanceScreen({super.key, required this.userId});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  Map<DateTime, String> _attendanceStatus = {};
  List<Map<String, dynamic>> _attendanceDetails = [];
  List<Map<String, dynamic>> _filteredAttendanceDetails = [];
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _attendanceStats = {};
  bool isLoading = true;

  // Coursera color palette
  final Color primaryColor = Color(0xFF2A73CC); // Coursera blue
  final Color secondaryColor = Color(0xFF4A90E2); // Lighter blue
  final Color accentColor = Color(0xFF0056D2); // Darker blue

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      await Future.wait([
        _fetchAttendance(),
        _fetchAttendanceStats()
      ]);
    } catch (e) {
      print("Error loading data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchAttendance() async {
    try {
      final response = await http.get(Uri.parse('https://apistudents.sainikschoolcadet.com/api/attendance/user/${widget.userId}'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        Map<DateTime, String> attendanceStatus = {};
        Map<DateTime, Map<String, dynamic>> latestAttendanceByDay = {};

        for (var item in data) {
          DateTime attendanceDate = DateTime.parse(item['attendance_date']).toLocal();
          DateTime dateWithoutTime = DateTime(attendanceDate.year, attendanceDate.month, attendanceDate.day);
          String status = item['status'];

          // Update status in the calendar view
          attendanceStatus[dateWithoutTime] = status;

          // For each day, keep only the latest record
          // Assuming the API returns data sorted by date, we overwrite any existing entry
          // If the API doesn't sort data, we would need to compare timestamps
          latestAttendanceByDay[dateWithoutTime] = {
            'date': attendanceDate,
            'status': status,
            'teacher_name': item['teacher_name'],
            'reason': item['reason'],
          };
        }

        // Convert map of latest records back to a list
        List<Map<String, dynamic>> attendanceDetails = latestAttendanceByDay.values.toList();

        setState(() {
          _attendanceStatus = attendanceStatus;
          _attendanceDetails = attendanceDetails;
          _filteredAttendanceDetails = [];
        });
      } else {
        throw Exception('Failed to load attendance data');
      }
    } catch (e) {
      print("Error fetching attendance: $e");
    }
  }

  Future<void> _fetchAttendanceStats() async {
    try {
      final response = await http.get(Uri.parse('https://apistudents.sainikschoolcadet.com/api/attendance/attendance_percentage/${widget.userId}'));

      if (response.statusCode == 200) {
        setState(() {
          _attendanceStats = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load attendance stats');
      }
    } catch (e) {
      print("Error fetching attendance stats: $e");
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Absent':
        return Colors.red;
      case 'Late':
        return Colors.orange; // Changed from yellow for better visibility
      default:
        return Colors.transparent;
    }
  }

  // Format date to "11th Jan 2025"
  String _formatDate(DateTime date) {
    final day = DateFormat('d').format(date);
    final month = DateFormat('MMM').format(date);
    final year = DateFormat('yyyy').format(date);

    String suffix = 'th';
    if (day == '1' || day == '21' || day == '31') {
      suffix = 'st';
    } else if (day == '2' || day == '22') {
      suffix = 'nd';
    } else if (day == '3' || day == '23') {
      suffix = 'rd';
    }

    return '$day$suffix $month $year';
  }

  // Generate days of the month
  List<Widget> _buildCalendarDays() {
    List<Widget> days = [];
    DateTime firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    DateTime lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);

    // Calculate the weekday of the first day (1 = Monday, 7 = Sunday)
    int firstWeekday = firstDayOfMonth.weekday;

    // Add empty containers for days before the start of the month
    for (int i = 1; i < firstWeekday; i++) {
      days.add(Container());
    }

    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      DateTime currentDay = DateTime(_selectedDate.year, _selectedDate.month, i);
      String status = _attendanceStatus[currentDay] ?? '';
      Color statusColor = _getStatusColor(status);

      days.add(GestureDetector(
        onTap: () {
          setState(() {
            _selectedDate = currentDay;

            // Filter to find the attendance record for this day
            // Since we've already processed the data to keep only the latest record per day,
            // there should be at most one match
            _filteredAttendanceDetails = _attendanceDetails.where((attendance) {
              DateTime attendanceDateWithoutTime = DateTime(
                  attendance['date'].year,
                  attendance['date'].month,
                  attendance['date'].day
              );
              return attendanceDateWithoutTime.isAtSameMomentAs(currentDay);
            }).toList();
          });
        },
        child: Container(
          margin: EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(statusColor == Colors.transparent ? 0 : 0.8),
            shape: BoxShape.circle,
            border: _selectedDate.day == currentDay.day && _selectedDate.month == currentDay.month
                ? Border.all(color: primaryColor, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '$i',
              style: TextStyle(
                color: statusColor == Colors.transparent ? Colors.black : Colors.white,
                fontWeight: _selectedDate.day == i ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          'Attendance Record',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
        elevation: 0,
      ),
      body: isLoading
          ? _buildLoadingState()
          : _buildScrollableContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
          SizedBox(height: 16),
          Text(
            'Loading attendance data...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableContent() {
    return RefreshIndicator(
      color: primaryColor,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Attendance Stats Card
              if (_attendanceStats.isNotEmpty)
                _buildAttendanceStatsCard(),

              SizedBox(height: 24),

              // Month Selector
              _buildMonthSelector(),

              // Weekdays
              _buildWeekdaysRow(),

              // Calendar Days
              Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 7,
                  children: _buildCalendarDays(),
                ),
              ),

              SizedBox(height: 16),

              // Selected Date Header
              Text(
                'Attendance Details for ${_formatDate(_selectedDate)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),

              SizedBox(height: 16),

              // Display filtered attendance details for the selected date
              _buildAttendanceDetails(),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStatsCard() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attendance Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.check_circle, 'Present', _attendanceStats['present_count']),
                  _buildStatItem(Icons.clear, 'Absent', _attendanceStats['absent_count']),
                  _buildStatItem(Icons.access_time, 'Late', _attendanceStats['late_count']),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Total Classes: ',
                    style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
                  ),
                  Text(
                    '${_attendanceStats['total_classes']}',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Attendance Percentage',
                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
              ),
              SizedBox(height: 8),
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: double.parse(_attendanceStats['attendance_percentage']) / 100,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: double.parse(_attendanceStats['attendance_percentage']) > 75
                            ? Colors.green
                            : (double.parse(_attendanceStats['attendance_percentage']) > 50
                            ? Colors.orange
                            : Colors.red),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${_attendanceStats['attendance_percentage']}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    String currentMonth = DateFormat('MMMM').format(_selectedDate);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryColor),
          onPressed: () {
            setState(() {
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
            });
          },
        ),
        Text(
          '$currentMonth ${_selectedDate.year}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward_ios, color: primaryColor),
          onPressed: () {
            setState(() {
              _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
            });
          },
        ),
      ],
    );
  }

  Widget _buildWeekdaysRow() {
    return Container(
      margin: EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final weekday = DateFormat('E').format(DateTime(2022, 1, 3 + index)); // Starting with Monday
          return Expanded(
            child: Text(
              weekday,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAttendanceDetails() {
    if (_filteredAttendanceDetails.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.grey[600]),
            SizedBox(width: 12),
            Text(
              "No attendance record found.",
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    // Since we're only showing the latest record per day,
    // there should be at most one record in the filtered list
    final attendance = _filteredAttendanceDetails[0];

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  attendance['status'] == 'Present'
                      ? Icons.check_circle
                      : (attendance['status'] == 'Absent'
                      ? Icons.cancel
                      : Icons.access_time),
                  color: _getStatusColor(attendance['status']),
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  attendance['status'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(attendance['status']),
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildDetailRow(Icons.person, 'Teacher', attendance['teacher_name']),
            if (attendance['reason'] != null && attendance['reason'].toString().isNotEmpty)
              _buildDetailRow(Icons.comment, 'Reason', attendance['reason']),

          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[600], size: 18),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build stat item for attendance counts
  Widget _buildStatItem(IconData icon, String label, dynamic value) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        SizedBox(height: 8),
        Text(value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}