import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../constants.dart';

class FeeStatusScreen extends StatefulWidget {
  final int userId;

  const FeeStatusScreen({super.key, required this.userId});

  @override
  _FeeStatusScreenState createState() => _FeeStatusScreenState();
}

class _FeeStatusScreenState extends State<FeeStatusScreen> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? feeStatus;
  List<Map<String, dynamic>> feePayments = [];
  List<Map<String, dynamic>> otherCharges = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  late TabController _tabController;

  // Coursera color palette
  final Color primaryColor = Color(0xFF2A73CC); // Coursera blue
  final Color secondaryColor = Color(0xFF4A90E2); // Lighter blue
  final Color accentColor = Color(0xFF0056D2); // Darker blue

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Force rebuild when tab changes
      setState(() {});
    });
    _fetchFeeStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFeeStatus() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(Uri.parse('$BASE_URL/feestatus/user/${widget.userId}'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            feeStatus = data[0];
          });
          await _fetchFeePayments(feeStatus!['id']);
          await _fetchOtherCharges(feeStatus!['id']);
        }
      } else {
        throw Exception('Failed to load fee status');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
      });
      print("Error fetching fee status: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchFeePayments(int feeStatusId) async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/feepaymentrecords/payments/$feeStatusId'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        feePayments = List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load fee payment records');
      }
    } catch (e) {
      print("Error fetching fee payments: $e");
    }
  }

  Future<void> _fetchOtherCharges(int feeStatusId) async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/otherchargesrecords/charges/$feeStatusId'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        otherCharges = List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Failed to load other charges');
      }
    } catch (e) {
      print("Error fetching other charges: $e");
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'N/A') {
      return 'Not Available';
    }

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Fee Status',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchFeeStatus,
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : (hasError
          ? _buildErrorState()
          : (feeStatus == null
          ? _buildEmptyState()
          : _buildScrollableContent())),
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
            'Loading your fee information...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
              'No Records Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
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
              onPressed: _fetchFeeStatus,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No fee information found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please check with your administration',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.refresh),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: _fetchFeeStatus,
          ),
        ],
      ),
    );
  }

  // New fully scrollable content layout
  Widget _buildScrollableContent() {
    return DefaultTabController(
      length: 2,
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildFeeSummaryCard(),
            ),
            SliverToBoxAdapter(
              child: _buildTabBar(),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPaymentsTab(),
            _buildChargesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeSummaryCard() {
    // Calculate fee metrics
    final totalFees = int.tryParse(feeStatus?['totalFees']?.toString() ?? '0') ?? 0;
    final feesSubmitted = int.tryParse(feeStatus?['feesSubmitted']?.toString() ?? '0') ?? 0;
    final remainingFees = int.tryParse(feeStatus?['remainingFees']?.toString() ?? '0') ?? 0;

    // Calculate payment percentage
    double paymentPercentage = 0;
    if (totalFees > 0) {
      paymentPercentage = (feesSubmitted / totalFees) * 100;
    }

    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fee Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDate(feeStatus?['admissionDate']),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: paymentPercentage.round(),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.7),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(10),
                      right: paymentPercentage >= 100 ? Radius.circular(10) : Radius.zero,
                    ),
                  ),
                ),
              ),
              if (paymentPercentage < 100)
                Expanded(
                  flex: (100 - paymentPercentage).round(),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(10),
                        left: paymentPercentage <= 0 ? Radius.circular(10) : Radius.zero,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paid: ${paymentPercentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                'Due: ${(100 - paymentPercentage).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.3)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Paid', 'Rs $feesSubmitted'),
              _buildSummaryItem('Due', 'Rs $remainingFees'),
            ],
          ),
          SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.3)),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.event_note,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Next Payment Due:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatDate(feeStatus?['nextDueDate']),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: primaryColor,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[700],
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          tabAlignment: TabAlignment.fill,
          tabs: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Tab(
                icon: Icon(Icons.payment),
                text: 'Payments',
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Tab(
                icon: Icon(Icons.receipt_long),
                text: 'Charges',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab() {
    if (feePayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No payment records found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: feePayments.length,
      itemBuilder: (context, index) {
        final payment = feePayments[index];
        return _buildTransactionCard(
          title: payment['title'] ?? 'Payment',
          date: _formatDate(payment['date']),
          amount: 'Rs ${payment['amount']}',
          isPayment: true,
          index: index,
        );
      },
    );
  }

  Widget _buildChargesTab() {
    if (otherCharges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 60,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No additional charges found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      physics: AlwaysScrollableScrollPhysics(),
      itemCount: otherCharges.length,
      itemBuilder: (context, index) {
        final charge = otherCharges[index];
        return _buildTransactionCard(
          title: charge['title'] ?? 'Charge',
          date: _formatDate(charge['date']),
          amount: 'Rs ${charge['amount']}',
          isPayment: false,
          index: index,
        );
      },
    );
  }

  Widget _buildTransactionCard({
    required String title,
    required String date,
    required String amount,
    required bool isPayment,
    required int index,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isPayment ? Colors.green : Colors.red).withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isPayment ? Colors.green : Colors.red).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPayment ? Icons.arrow_upward : Icons.arrow_downward,
            color: isPayment ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 12,
              color: Colors.grey[500],
            ),
            SizedBox(width: 4),
            Text(
              date,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isPayment ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}