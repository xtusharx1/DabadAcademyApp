import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import 'package:intl/intl.dart';

class TestResultScreen extends StatefulWidget {
  final int userId;

  const TestResultScreen({super.key, required this.userId});

  @override
  _TestResultScreenState createState() => _TestResultScreenState();
}

class _TestResultScreenState extends State<TestResultScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> testRecords = [];
  List<Map<String, dynamic>> testDetails = [];
  Map<int, String> batchNameMap = {}; // Map to store batch names
  Map<int, int> testRanks = {};

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
      final records = await fetchTestRecords();

      // Fetch details and ranks in parallel
      final detailsFutures = records.map((record) async {
        try {
          return await fetchTestDetails(record['test_id']);
        } catch (e) {
          print('Error fetching test details: $e');
          return <String, dynamic>{};
        }
      }).toList();

      final ranksFutures = records.map((record) async {
        try {
          return await fetchRank(record['test_id'], widget.userId);
        } catch (e) {
          print('Error fetching rank: $e');
          return 0;
        }
      }).toList();

      final details = await Future.wait(detailsFutures);
      final ranksList = await Future.wait(ranksFutures);

      Map<int, int> ranks = {};
      for (int i = 0; i < records.length; i++) {
        ranks[records[i]['test_id']] = ranksList[i];
      }

      // Collect unique batch IDs
      Set<int> batchIds = {};
      for (var detail in details) {
        if (detail.containsKey('batch_id')) {
          batchIds.add(detail['batch_id']);
        }
      }

      // Fetch batch names for all batches in parallel
      Map<int, String> batchNames = {};
      final batchIdsList = batchIds.toList();
      final batchFutures = batchIdsList.map((batchId) async {
        try {
          final batchInfo = await fetchBatchInfo(batchId);
          return MapEntry<int, String>(batchId, (batchInfo['batch_name'] as String?) ?? 'Unknown Batch');
        } catch (e) {
          print('Error fetching batch info for ID $batchId: $e');
          return MapEntry<int, String>(batchId, 'Batch $batchId');
        }
      }).toList();

      final batchEntries = await Future.wait(batchFutures);
      batchNames.addEntries(batchEntries);

      setState(() {
        testRecords = records;
        testDetails = details;
        batchNameMap = batchNames;
        testRanks = ranks;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error loading data: $e');
    }
  }

  Future<int> fetchRank(int testId, int userId) async {
    try {
      final response = await http.get(
          Uri.parse('$BASE_URL/studenttestrecords/rank/$testId/$userId')
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['rank'];
      } else {
        print('Failed to load rank data: ${response.statusCode} ${response
            .body}');
        return 0; // Default if unable to get rank
      }
    } catch (e) {
      print('Error fetching rank: $e');
      return 0; // Default if error occurs
    }
  }

  Future<List<Map<String, dynamic>>> fetchTestRecords() async {
    final response = await http.get(
        Uri.parse('$BASE_URL/studenttestrecords/user/${widget.userId}'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      print('Failed to load test records: ${response.statusCode} ${response
          .body}');
      throw Exception('Failed to load test records');
    }
  }

  Future<Map<String, dynamic>> fetchTestDetails(int testId) async {
    final response = await http.get(Uri.parse('$BASE_URL/test/$testId'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load test details');
    }
  }

  // Add new method to fetch batch information
  Future<Map<String, dynamic>> fetchBatchInfo(int batchId) async {
    final response = await http.get(Uri.parse('$BASE_URL/batches/$batchId'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load batch info');
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Academic Performance',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : (testRecords.isEmpty
              ? _buildEmptyState()
              : ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildOverviewSection(),
                    const SizedBox(height: 4),
                    _buildSectionHeader(),
                    _buildRecordsContent(),
                    const SizedBox(height: 24),
                  ],
                )),
    );
  }

  Widget _buildOverviewSection() {
    double totalPercentage = 0;
    int totalRank = 0;
    int rankCount = 0;
    String strongestSubject = '';
    String weakestSubject = '';
    Map<String, List<double>> subjectScores = {};

    for (int i = 0; i < testRecords.length; i++) {
      final record = testRecords[i];
      final details = testDetails[i];
      final pct = (record['marks_obtained'] / details['total_marks']) * 100;
      totalPercentage += pct;
      final subject = (details['subject'] ?? 'General') as String;
      subjectScores.putIfAbsent(subject, () => []);
      subjectScores[subject]!.add(pct);
      final testId = record['test_id'];
      final rank = testRanks[testId] ?? 0;
      if (rank > 0) { totalRank += rank; rankCount++; }
    }

    final avg = testRecords.isEmpty ? 0.0 : totalPercentage / testRecords.length;
    final avgRank = rankCount > 0 ? (totalRank / rankCount).round() : 0;

    double bestAvg = 0, worstAvg = 100;
    subjectScores.forEach((subj, scores) {
      final sa = scores.reduce((a, b) => a + b) / scores.length;
      if (sa > bestAvg) { bestAvg = sa; strongestSubject = subj; }
      if (sa < worstAvg) { worstAvg = sa; weakestSubject = subj; }
    });

    // Status badge config
    String statusLabel;
    Color statusColor;
    Color statusBg;
    if (avg >= 80) {
      statusLabel = 'Excellent';
      statusColor = const Color(0xFF2E7D32);
      statusBg = const Color(0xFFE8F5E9);
    } else if (avg >= 60) {
      statusLabel = 'Good';
      statusColor = const Color(0xFF1565C0);
      statusBg = const Color(0xFFE3F2FD);
    } else if (avg >= 40) {
      statusLabel = 'Average';
      statusColor = const Color(0xFFE65100);
      statusBg = const Color(0xFFFBE9E7);
    } else {
      statusLabel = 'Needs Work';
      statusColor = const Color(0xFFC62828);
      statusBg = const Color(0xFFFFEBEE);
    }

    // Insight text
    String insightText;
    if (strongestSubject.isNotEmpty && weakestSubject.isNotEmpty && strongestSubject != weakestSubject) {
      insightText = 'Your strongest area is $strongestSubject. Focusing more on ${weakestSubject.toUpperCase()} could significantly boost your overall score.';
    } else if (avg >= 75) {
      insightText = 'Outstanding performance! Keep up the consistent effort across all subjects.';
    } else if (avg >= 50) {
      insightText = "You're on the right track. Consistent revision and practice tests will push your scores higher.";
    } else {
      insightText = 'Focus on core concepts and regular practice. Short, focused study sessions will build momentum.';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top row: Left stats | Right ring ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT: two stacked stat mini-cards — natural width, no fixed size
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStatMiniCard(
                          icon: Icons.menu_book_rounded,
                          label: 'Tests Taken',
                          value: '${testRecords.length}',
                        ),
                        const SizedBox(height: 12),
                        _buildStatMiniCard(
                          icon: Icons.emoji_events_rounded,
                          label: 'Average Rank',
                          value: avgRank > 0 ? '#$avgRank' : '—',
                        ),
                      ],
                    ),
                  ),

                  // Vertical divider
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 14),
                    color: const Color(0xFFEEEEEE),
                  ),

                  // RIGHT: fixed 130px ring, centered in remaining space
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 130,
                        height: 130,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 130,
                              height: 130,
                              child: CircularProgressIndicator(
                                value: avg / 100,
                                strokeWidth: 11,
                                backgroundColor: const Color(0xFFE3EBF6),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF1565C0)),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${avg.toStringAsFixed(0)}%',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1A1A2E),
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Overall\nPerformance',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Insight strip ──────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lightbulb icon badge
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCEAFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFF1565C0),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Insight',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        insightText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[700],
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Target icon on the right
                Icon(
                  Icons.gps_fixed_rounded,
                  color: const Color(0xFF1565C0).withOpacity(0.4),
                  size: 36,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatMiniCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEAFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 18),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A2E),
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            'TEST RESULTS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Colors.grey[400],
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Divider(color: Colors.grey[200], thickness: 1)),
        ],
      ),
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
          const SizedBox(height: 16),
          Text(
            'Loading your performance data...',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No test records found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            onPressed: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsContent() {
    if (testRecords.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: List.generate(testRecords.length, (index) {
          final record = testRecords[index];
          final details = testDetails.length > index ? testDetails[index] : null;
          if (details == null) return const SizedBox.shrink();

          final double percentage =
              (record['marks_obtained'] / details['total_marks']) * 100;
          final DateTime date = DateTime.parse(details['date']);
          final String formattedDate = DateFormat('MMM dd, yyyy').format(date);
          final String subject = details['subject'] ?? 'N/A';

          return _buildTestResultCard(
            title: details['test_name'],
            subject: subject,
            date: formattedDate,
            score: record['marks_obtained'].toString(),
            total: details['total_marks'].toString(),
            percentage: percentage,
            index: index,
          );
        }),
      ),
    );
  }

  Widget _buildTestResultCard({
    required String title,
    required String subject,
    required String date,
    required String score,
    required String total,
    required double percentage,
    required int index,
  }) {
    Color progressColor;
    String grade;
    Color gradeColor;
    Color gradeBg;

    if (percentage >= 75) {
      progressColor = Colors.green;
      grade = 'Excellent';
      gradeColor = Colors.green[700]!;
      gradeBg = const Color(0xFFE8F5E9);
    } else if (percentage >= 60) {
      progressColor = Colors.orange;
      grade = 'Good';
      gradeColor = Colors.orange[700]!;
      gradeBg = const Color(0xFFFFF3E0);
    } else if (percentage >= 40) {
      progressColor = Colors.deepOrange;
      grade = 'Average';
      gradeColor = Colors.deepOrange[700]!;
      gradeBg = const Color(0xFFFBE9E7);
    } else {
      progressColor = Colors.red;
      grade = 'Needs Work';
      gradeColor = Colors.red[700]!;
      gradeBg = const Color(0xFFFFEBEE);
    }

    final testId = testRecords[index]['test_id'];
    final rank = testRanks[testId] ?? 0;
    final rankDisplay = rank > 0 ? '#$rank' : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // S.No badge
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 10, top: 2),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[850],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Icon(Icons.book_outlined,
                              size: 13,
                              color: primaryColor.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            subject,
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: gradeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    grade,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: gradeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[100],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(progressColor),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMeta(Icons.calendar_month_outlined, date),
                _buildMetaDivider(),
                _buildMeta(Icons.score_outlined, '$score / $total'),
                _buildMetaDivider(),
                _buildMeta(Icons.emoji_events_outlined, rankDisplay),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeta(IconData icon, String text) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaDivider() {
    return Container(width: 1, height: 16, color: Colors.grey[200]);
  }
}
