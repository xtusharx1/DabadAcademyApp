import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../constants.dart';
import 'package:http_parser/http_parser.dart';
import 'package:url_launcher/url_launcher.dart';
class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({super.key, required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  bool isLoading = true;
  bool isUploading = false;
  bool hasError = false;
  bool isEditing = false;
  bool isSavingProfile = false;
  String errorMessage = '';
  Map<String, dynamic>? userData;
  Map<String, dynamic>? documentsData;
  late TabController _tabController;
  int _currentTabIndex = 0;

  // Registration number controllers
  final TextEditingController _srnController = TextEditingController();
  final TextEditingController _penController = TextEditingController();

  // Profile editing controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _childAadharController = TextEditingController();
  final TextEditingController _motherAadharController = TextEditingController();
  final TextEditingController _fatherAadharController = TextEditingController();
  final TextEditingController _previousSchoolController = TextEditingController();

  // Date controllers
  DateTime? _selectedDateOfBirth;
  DateTime? _selectedDateOfAdmission;

  // Dropdown values
  String? _selectedGender;
  String? _selectedStatus;
  String? _selectedClass;

  // Colors
  final Color primaryColor = Color(0xFF2A73CC);
  final Color secondaryColor = Color(0xFF4A90E2);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _fetchUserDetails();
    _fetchStudentDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _srnController.dispose();
    _penController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _fatherNameController.dispose();
    _motherNameController.dispose();
    _addressController.dispose();
    _stateController.dispose();
    _childAadharController.dispose();
    _motherAadharController.dispose();
    _fatherAadharController.dispose();
    _previousSchoolController.dispose();
    super.dispose();
  }

  void _populateEditingControllers(Map<String, dynamic> user) {
    _nameController.text = user['name'] ?? '';
    _emailController.text = user['email'] ?? '';
    _phoneController.text = user['phone_number'] ?? '';
    _fatherNameController.text = user['father_name'] ?? '';
    _motherNameController.text = user['mother_name'] ?? '';
    _addressController.text = user['full_address'] ?? '';
    _stateController.text = user['state'] ?? '';
    _childAadharController.text = user['child_aadhar_number'] ?? '';
    _motherAadharController.text = user['mother_aadhar_number'] ?? '';
    _fatherAadharController.text = user['father_aadhar_number'] ?? '';
    _previousSchoolController.text = user['previous_school_info'] ?? '';

    _selectedGender = user['gender'];
    _selectedStatus = user['status'];
    _selectedClass = user['present_class'];

    // Parse dates
    try {
      if (user['date_of_birth'] != null && user['date_of_birth'] != 'N/A') {
        _selectedDateOfBirth = DateTime.parse(user['date_of_birth']);
      }
    } catch (e) {
      _selectedDateOfBirth = null;
    }

    try {
      if (user['date_of_admission'] != null && user['date_of_admission'] != 'N/A') {
        _selectedDateOfAdmission = DateTime.parse(user['date_of_admission']);
      }
    } catch (e) {
      _selectedDateOfAdmission = null;
    }
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await http.get(Uri.parse('$BASE_URL/users/user/${widget.userId}'));

      if (response.statusCode == 200) {
        setState(() {
          userData = jsonDecode(response.body);
          isLoading = false;
        });

        // Populate editing controllers
        if (userData != null) {
          _populateEditingControllers(userData!['user']);
        }
      } else {
        throw Exception('Failed to load user details');
      }
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _saveProfileChanges() async {
    setState(() => isSavingProfile = true);

    try {
      // Create update data with only non-empty values
      final updateData = <String, dynamic>{};

      // Basic Information - only add if not empty
      if (_nameController.text.trim().isNotEmpty) {
        updateData['name'] = _nameController.text.trim();
      }
      if (_emailController.text.trim().isNotEmpty) {
        updateData['email'] = _emailController.text.trim();
      }
      if (_phoneController.text.trim().isNotEmpty) {
        updateData['phone_number'] = _phoneController.text.trim();
      }

      // Family Information
      if (_fatherNameController.text.trim().isNotEmpty) {
        updateData['father_name'] = _fatherNameController.text.trim();
      }
      if (_motherNameController.text.trim().isNotEmpty) {
        updateData['mother_name'] = _motherNameController.text.trim();
      }

      // Contact Information
      if (_addressController.text.trim().isNotEmpty) {
        updateData['full_address'] = _addressController.text.trim();
      }
      if (_stateController.text.trim().isNotEmpty) {
        updateData['state'] = _stateController.text.trim();
      }

      // Identification Numbers
      if (_childAadharController.text.trim().isNotEmpty) {
        updateData['child_aadhar_number'] = _childAadharController.text.trim();
      }
      if (_motherAadharController.text.trim().isNotEmpty) {
        updateData['mother_aadhar_number'] = _motherAadharController.text.trim();
      }
      if (_fatherAadharController.text.trim().isNotEmpty) {
        updateData['father_aadhar_number'] = _fatherAadharController.text.trim();
      }

      // Previous School Info
      if (_previousSchoolController.text.trim().isNotEmpty) {
        updateData['previous_school_info'] = _previousSchoolController.text.trim();
      }

      // Dropdown values - only add if selected and not null
      if (_selectedGender != null && _selectedGender!.isNotEmpty) {
        updateData['gender'] = _selectedGender;
      }
      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        updateData['status'] = _selectedStatus;
      }
      if (_selectedClass != null && _selectedClass!.isNotEmpty) {
        updateData['present_class'] = _selectedClass;
      }

      // Dates - format properly for backend
      if (_selectedDateOfBirth != null) {
        updateData['date_of_birth'] = _selectedDateOfBirth!.toIso8601String().split('T')[0];
      }
      if (_selectedDateOfAdmission != null) {
        updateData['date_of_admission'] = _selectedDateOfAdmission!.toIso8601String().split('T')[0];
      }

      // Validate that we have at least one field to update
      if (updateData.isEmpty) {
        _showErrorSnackBar('No changes to save');
        return;
      }

      // Email validation if email is being updated
      if (updateData.containsKey('email')) {
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(updateData['email'])) {
          _showErrorSnackBar('Please enter a valid email address');
          return;
        }
      }

      // Phone number validation if phone is being updated
      if (updateData.containsKey('phone_number')) {
        final phoneRegex = RegExp(r'^\d{10}$');
        if (!phoneRegex.hasMatch(updateData['phone_number'].replaceAll(RegExp(r'[^\d]'), ''))) {
          _showErrorSnackBar('Please enter a valid 10-digit phone number');
          return;
        }
      }

      print('=== PROFILE UPDATE DEBUG ===');
      print('User ID: ${widget.userId}');
      print('Update URL: $BASE_URL/users/user/${widget.userId}');
      print('Update Data: ${jsonEncode(updateData)}');
      print('Fields being updated: ${updateData.keys.join(', ')}');

      final response = await http.put(
        Uri.parse('$BASE_URL/users/user/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'DabadAcademyApp/1.0',
        },
        body: jsonEncode(updateData),
      );

      print('=== RESPONSE DEBUG ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          _showSuccessSnackBar(responseData['message'] ?? 'Profile updated successfully!');
          setState(() {
            isEditing = false;
          });
          await _fetchUserDetails(); // Refresh data
        } catch (e) {
          // Even if JSON parsing fails, treat 200 as success
          _showSuccessSnackBar('Profile updated successfully!');
          setState(() {
            isEditing = false;
          });
          await _fetchUserDetails();
        }
      } else {
        String errorMessage;
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? 'Update failed';

          // Log detailed error information
          print('=== ERROR DETAILS ===');
          print('Error Message: $errorMessage');
          if (errorData.containsKey('error')) {
            print('Error Details: ${errorData['error']}');
          }
          if (errorData.containsKey('errors')) {
            print('Validation Errors: ${errorData['errors']}');
          }
        } catch (e) {
          errorMessage = 'Server error (${response.statusCode})';
          if (response.statusCode == 400) {
            errorMessage = 'Invalid data provided. Please check your input.';
          } else if (response.statusCode == 404) {
            errorMessage = 'User not found. Please try again.';
          } else if (response.statusCode == 500) {
            errorMessage = 'Server error. Please try again later.';
          }
        }
        throw Exception(errorMessage);
      }
    } on http.ClientException catch (e) {
      print('Network Error: $e');
      _showErrorSnackBar('Network error. Please check your internet connection.');
    } on FormatException catch (e) {
      print('JSON Format Error: $e');
      _showErrorSnackBar('Invalid server response. Please try again.');
    } catch (e) {
      print('=== SAVE PROFILE ERROR ===');
      print('Exception: $e');
      print('Exception Type: ${e.runtimeType}');

      String userFriendlyMessage;
      if (e.toString().contains('SocketException')) {
        userFriendlyMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('TimeoutException')) {
        userFriendlyMessage = 'Request timed out. Please try again.';
      } else {
        userFriendlyMessage = e.toString().replaceAll('Exception: ', '');
      }

      _showErrorSnackBar(userFriendlyMessage);
    } finally {
      setState(() => isSavingProfile = false);
    }
  }
  Future<void> _selectDate(BuildContext context, bool isDateOfBirth) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDateOfBirth
          ? (_selectedDateOfBirth ?? DateTime(2000))
          : (_selectedDateOfAdmission ?? DateTime.now()),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDateOfBirth) {
          _selectedDateOfBirth = picked;
        } else {
          _selectedDateOfAdmission = picked;
        }
      });
    }
  }

  Widget _buildEditableInfoCard(String title, TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final value = controller.text.trim();
    final isValEmptyOrNA = value.isEmpty || value.toLowerCase() == 'n/a' || value.toLowerCase() == 'not available';
    if (!isEditing && isValEmptyOrNA) {
      return SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: Offset(0, 2))],
        border: isEditing ? Border.all(color: primaryColor.withOpacity(0.3), width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500, fontSize: 14)),
          SizedBox(height: 8),
          isEditing
              ? TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
              filled: true,
              fillColor: Colors.grey[50],
            ),
            style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
          )
              : Text(
            controller.text.isEmpty ? 'N/A' : controller.text,
            style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDropdownCard(String title, String? currentValue, List<String> options, Function(String?) onChanged) {
    final val = currentValue?.trim() ?? '';
    final isValEmptyOrNA = val.isEmpty || val.toLowerCase() == 'n/a' || val.toLowerCase() == 'not available';
    if (!isEditing && isValEmptyOrNA) {
      return SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: Offset(0, 2))],
        border: isEditing ? Border.all(color: primaryColor.withOpacity(0.3), width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500, fontSize: 14)),
          SizedBox(height: 8),
          isEditing
              ? DropdownButtonFormField<String>(
            value: options.contains(currentValue) ? currentValue : null, // Only set value if it exists in options
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
              filled: true,
              fillColor: Colors.grey[50],
            ),
            hint: Text('Select $title'), // Add hint text when no value is selected
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: onChanged,
            style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
            dropdownColor: Colors.white,
          )
              : Text(
            currentValue ?? 'N/A',
            style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableDateCard(String title, DateTime? selectedDate, VoidCallback onTap) {
    if (!isEditing && selectedDate == null) {
      return SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: Offset(0, 2))],
        border: isEditing ? Border.all(color: primaryColor.withOpacity(0.3), width: 1) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500, fontSize: 14)),
          SizedBox(height: 8),
          isEditing
              ? GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedDate != null
                          ? DateFormat('MMMM dd, yyyy').format(selectedDate)
                          : 'Select date',
                      style: TextStyle(
                          fontSize: 16,
                          color: selectedDate != null ? Colors.black87 : Colors.grey[600],
                          fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                  Icon(Icons.calendar_today, color: primaryColor, size: 20),
                ],
              ),
            ),
          )
              : Text(
            selectedDate != null
                ? DateFormat('MMMM dd, yyyy').format(selectedDate)
                : 'Not Available',
            style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
  // Keep all existing methods for document management, file upload, etc.
  Future<void> _fetchStudentDocuments() async {
    try {
      final response = await http.get(Uri.parse('$BASE_URL/documents/student-documents/${widget.userId}'));
      if (response.statusCode == 200) {
        setState(() {
          documentsData = jsonDecode(response.body);
          _srnController.text = documentsData?['srn_number'] ?? '';
          _penController.text = documentsData?['pen_number'] ?? '';
        });
      } else if (response.statusCode == 404) {
        setState(() {
          documentsData = {};
        });
      }
    } catch (e) {
      print("Error fetching documents: $e");
    }
  }

  Future<void> _updateNumbers() async {
    if (_srnController.text.isEmpty && _penController.text.isEmpty) {
      _showErrorSnackBar('Please enter at least one number');
      return;
    }

    setState(() => isUploading = true);

    try {
      final url = '$BASE_URL/documents/student-documents/${widget.userId}/numbers';
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'srn_number': _srnController.text.trim(),
          'pen_number': _penController.text.trim(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        _showSuccessSnackBar(responseData['message'] ?? 'Numbers updated successfully!');
        await _fetchStudentDocuments();
      } else {
        String errorMessage;
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? 'Update failed';
        } catch (e) {
          errorMessage = 'Server error (${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> uploadFileWithHttp(String url, File file, String documentType, String title) async {
    try {
      setState(() => isUploading = true);

      var request = http.MultipartRequest('PUT', Uri.parse(url));

      // Get the file extension
      String fileName = file.path.split('/').last;
      String fileExtension = fileName.split('.').last.toLowerCase();

      // Sanitize filename - remove spaces, parentheses, and special characters
      String sanitizedFileName = fileName
          .replaceAll(RegExp(r'[^\w\.]'), '_') // Replace non-word characters except dots with underscore
          .replaceAll(RegExp(r'_+'), '_') // Replace multiple underscores with single
          .replaceAll(RegExp(r'^_|_$'), ''); // Remove leading/trailing underscores

      // Ensure the sanitized filename has the original extension
      if (!sanitizedFileName.toLowerCase().endsWith('.$fileExtension')) {
        sanitizedFileName = '${sanitizedFileName.split('.').first}.$fileExtension';
      }

      print('Original filename: $fileName');
      print('Sanitized filename: $sanitizedFileName');
      print('File extension: $fileExtension');

      // Validate file type
      List<String> allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
      if (!allowedExtensions.contains(fileExtension)) {
        throw Exception('Invalid file type. Only PDF, JPG, JPEG, and PNG files are allowed.');
      }

      // Determine MIME type based on file extension - matching server expectations exactly
      String mimeType;
      switch (fileExtension) {
        case 'pdf':
          mimeType = 'application/pdf';
          break;
        case 'jpg':
          mimeType = 'image/jpeg'; // Use image/jpeg for JPG files (not image/jpg)
          break;
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        default:
          throw Exception('Unsupported file type: $fileExtension');
      }

      print('MIME type: $mimeType');

      // Read file content to verify it's not corrupted
      final fileBytes = await file.readAsBytes();
      print('File size in bytes: ${fileBytes.length}');

      // Basic file signature validation
      if (fileExtension == 'pdf') {
        // PDF files should start with %PDF
        if (fileBytes.length < 4 ||
            fileBytes[0] != 0x25 || fileBytes[1] != 0x50 ||
            fileBytes[2] != 0x44 || fileBytes[3] != 0x46) {
          throw Exception('File appears to be corrupted or is not a valid PDF');
        }
        print('PDF signature validation: PASSED');
      }

      // Add the file to the request with explicit MIME type
      request.files.add(http.MultipartFile.fromBytes(
        'document',
        fileBytes,
        filename: sanitizedFileName,
        contentType: MediaType.parse(mimeType), // Explicitly set correct MIME type
      ));

      // Add any additional fields if needed
      request.fields['document_type'] = documentType;
      request.fields['user_id'] = widget.userId.toString();

      print('Uploading to: $url');
      print('Document type: $documentType');
      print('File path: ${file.path}');
      print('Using filename: $sanitizedFileName');
      print('Content-Type: $mimeType');

      // Send the request
      var response = await request.send();

      // Get response body
      final responseBody = await response.stream.bytesToString();

      print('Upload response status: ${response.statusCode}');
      print('Upload response body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(responseBody);
        _showSuccessSnackBar(responseData['message'] ?? '$title uploaded successfully!');
        await _fetchStudentDocuments();
      } else {
        String errorMessage;
        try {
          // Try to parse JSON error first
          final errorData = jsonDecode(responseBody);
          errorMessage = errorData['message'] ?? 'Upload failed';
        } catch (e) {
          // If JSON parsing fails, check if it's HTML error page
          if (responseBody.contains('Error:') && responseBody.contains('<html>')) {
            // Extract error message from HTML
            RegExp regExp = RegExp(r'Error: ([^<\n]+)');
            Match? match = regExp.firstMatch(responseBody);
            if (match != null) {
              errorMessage = match.group(1) ?? 'Server error';
            } else {
              errorMessage = 'Server returned an error page';
            }
          } else {
            errorMessage = 'Server error (${response.statusCode})';
          }
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Upload error: $e');
      _showErrorSnackBar('Upload failed: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> _uploadDocument(String documentType, String title) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);

        // Additional file validation
        String fileName = file.path.split('/').last;
        String fileExtension = fileName.split('.').last.toLowerCase();

        // Double-check file extension
        List<String> allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png'];
        if (!allowedExtensions.contains(fileExtension)) {
          _showErrorSnackBar('Invalid file type. Please select a PDF, JPG, JPEG, or PNG file.');
          return;
        }

        // Check file size (10MB limit)
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          _showErrorSnackBar('File too large. Maximum size is 10MB.');
          return;
        }

        // Check if file exists
        if (!await file.exists()) {
          _showErrorSnackBar('Selected file does not exist or is not accessible.');
          return;
        }

        // Additional file content validation
        try {
          final fileBytes = await file.readAsBytes();

          // Validate PDF files
          if (fileExtension == 'pdf') {
            if (fileBytes.length < 4 ||
                fileBytes[0] != 0x25 || fileBytes[1] != 0x50 ||
                fileBytes[2] != 0x44 || fileBytes[3] != 0x46) {
              _showErrorSnackBar('The selected file is not a valid PDF. Please choose a different file.');
              return;
            }
          }

          // Validate image files
          if (['jpg', 'jpeg', 'png'].contains(fileExtension)) {
            // Basic image signature validation
            bool isValidImage = false;

            if (fileExtension == 'png' && fileBytes.length >= 8) {
              // PNG signature: 89 50 4E 47 0D 0A 1A 0A
              isValidImage = fileBytes[0] == 0x89 && fileBytes[1] == 0x50 &&
                  fileBytes[2] == 0x4E && fileBytes[3] == 0x47;
            } else if ((fileExtension == 'jpg' || fileExtension == 'jpeg') && fileBytes.length >= 3) {
              // JPEG signature: FF D8 FF
              isValidImage = fileBytes[0] == 0xFF && fileBytes[1] == 0xD8 && fileBytes[2] == 0xFF;
            }

            if (!isValidImage) {
              _showErrorSnackBar('The selected file is not a valid ${fileExtension.toUpperCase()} image. Please choose a different file.');
              return;
            }
          }

          print('File validation: PASSED');
        } catch (e) {
          _showErrorSnackBar('Error validating file: ${e.toString()}');
          return;
        }

        print('Selected file: $fileName');
        print('File size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        print('File extension: $fileExtension');

        // Show confirmation dialog
        bool? shouldUpload = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Confirm Upload'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Document: $title'),
                SizedBox(height: 8),
                Text('File: $fileName'),
                SizedBox(height: 8),
                Text('Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB'),
                SizedBox(height: 8),
                Text('Type: ${fileExtension.toUpperCase()}'),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 4),
                      Text('File validated successfully',
                          style: TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text('Upload'),
              ),
            ],
          ),
        );

        if (shouldUpload == true) {
          // Upload the file
          final url = '$BASE_URL/documents/student-documents/${widget.userId}/document/$documentType';
          await uploadFileWithHttp(url, file, documentType, title);
        }
      } else {
        // User canceled the picker
        print('File selection canceled');
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting file: ${e.toString()}');
    }
  }

  Future<void> _viewDocument(String? url, String documentName) async {
    if (url == null || url.isEmpty) {
      _showErrorSnackBar('$documentName is not available');
      return;
    }

    // Check if it's a full URL or relative path
    String fullUrl = url.startsWith('http') ? url : '$BASE_URL/$url';

    showDialog(
        context: context,
        builder: (context) => Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
        // Header
        Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                documentName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      // Content
      Padding(
          padding: EdgeInsets.all(16),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Image preview for image files
              if (url.toLowerCase().contains('.jpg') ||
              url.toLowerCase().contains('.jpeg') ||
              url.toLowerCase().contains('.png'))
      Container(
      width: double.infinity,
      constraints: BoxConstraints(maxHeight: 300),
      child: Image.network(
        fullUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return SizedBox(
            height: 150,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            height: 150,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 48, color: Colors.red),
                  SizedBox(height: 8),
                  Text('Failed to load image'),
                ],
              ),
            ),
          );
        },
      ),
    ),

                // Document info section for PDFs
                if (url.toLowerCase().contains('.pdf'))
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.picture_as_pdf,
                          size: 60,
                          color: Colors.red[400],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'PDF Document',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Click "Open in Browser" to view this PDF document',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                SizedBox(height: 16),

                // Single Open in Browser button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.open_in_browser),
                    label: Text('Open in Browser'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () async {
                      try {
                        final Uri uri = Uri.parse(fullUrl);

                        // Try different launch modes for better compatibility
                        bool launched = false;

                        // First try: External application (preferred for PDFs)
                        try {
                          launched = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                        } catch (e) {
                          print('External application launch failed: $e');
                        }

                        // Second try: External non-browser application
                        if (!launched) {
                          try {
                            launched = await launchUrl(
                              uri,
                              mode: LaunchMode.externalNonBrowserApplication,
                            );
                          } catch (e) {
                            print('External non-browser launch failed: $e');
                          }
                        }

                        // Third try: Platform default
                        if (!launched) {
                          try {
                            launched = await launchUrl(
                              uri,
                              mode: LaunchMode.platformDefault,
                            );
                          } catch (e) {
                            print('Platform default launch failed: $e');
                          }
                        }

                        // Fourth try: In-app web view (fallback)
                        if (!launched) {
                          try {
                            launched = await launchUrl(
                              uri,
                              mode: LaunchMode.inAppWebView,
                            );
                          } catch (e) {
                            print('In-app web view launch failed: $e');
                          }
                        }

                        if (launched) {
                          _showSuccessSnackBar('Opening document...');
                        } else {
                          // If all methods fail, show dialog with manual options
                          _showFallbackDialog(fullUrl, documentName);
                        }
                      } catch (e) {
                        print('URL launch error: $e');
                        _showFallbackDialog(fullUrl, documentName);
                      }
                    },
                  ),
                ),
                SizedBox(height: 12),

                // Compact help text
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Document will open in your browser app.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          ),
      ),
            ],
        ),
      ),
        ),
    );
  }

  // Fallback dialog when automatic URL opening fails
  void _showFallbackDialog(String url, String documentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unable to Open Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Could not automatically open the document. Please try one of these options:'),
            SizedBox(height: 16),
            Text('1. Copy the link and paste it in your browser'),
            SizedBox(height: 8),
            Text('2. Install a PDF viewer app from Play Store'),
            SizedBox(height: 8),
            Text('3. Use Chrome or another browser app'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              Navigator.pop(context);
              _showSuccessSnackBar('Document link copied to clipboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text('Copy Link'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == 'N/A') {
      return 'Not Available';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDateShort(String? date) {
    if (date == null || date.isEmpty || date == 'N/A') return 'N/A';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('MMM yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Edit/Save button
          if (_currentTabIndex == 0) // Only show on Personal Info tab
            IconButton(
              icon: Icon(
                isEditing ? Icons.save : Icons.edit,
                color: Colors.white,
              ),
              onPressed: isEditing ? _saveProfileChanges : () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
          // Cancel button when editing
          if (isEditing && _currentTabIndex == 0)
            IconButton(
              icon: Icon(Icons.cancel, color: Colors.white),
              onPressed: () {
                setState(() {
                  isEditing = false;
                });
                // Reset controllers to original values
                if (userData != null) {
                  _populateEditingControllers(userData!['user']);
                }
              },
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              await _fetchUserDetails();
              await _fetchStudentDocuments();
            },
          ),
        ],
      ),
      body: isLoading
          ? _buildLoadingState()
          : (hasError ? _buildErrorState() : _buildContent()),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
          SizedBox(height: 16),
          Text('Loading your profile...', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
              child: Icon(Icons.error_outline, color: Colors.red, size: 60),
            ),
            SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red[800]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(errorMessage, style: TextStyle(color: Colors.grey[700]), textAlign: TextAlign.center),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () async {
                await _fetchUserDetails();
                await _fetchStudentDocuments();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (userData == null) return Center(child: Text('No user data found'));

    final user = userData!['user'];

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildProfileHeader(user),
          SizedBox(height: 16),

          // Tab Bar - Scrolls with content
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(4),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(borderRadius: BorderRadius.circular(30), color: primaryColor),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[700],
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Tab(icon: Icon(Icons.person), text: 'Personal Info'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Tab(icon: Icon(Icons.folder), text: 'Documents'),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 16),

          // Tab Content - Changes based on selected tab and scrolls with page
          _currentTabIndex == 0
              ? _buildPersonalInfoSection(user)
              : _buildDocumentsSection(),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> user) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    user['name'] != null && user['name'].toString().isNotEmpty
                        ? user['name'].toString().substring(0, 1).toUpperCase()
                        : 'U',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['name'] ?? 'Student',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user['email'] ?? 'No email available',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      user['phone_number'] ?? 'No phone available',
                      style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
              // Edit indicator when in edit mode
              if (isEditing && _currentTabIndex == 0)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Editing', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.3)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Class', user['present_class'] ?? 'N/A', Icons.school),
              _buildSummaryItem('Joined', _formatDateShort(user['date_of_admission']), Icons.event),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        SizedBox(height: 8),
        Text(value, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }

  Widget _buildPersonalInfoSection(Map<String, dynamic> user) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
                ),
              ),
              if (isSavingProfile)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),

          _buildSectionTitle("Basic Information"),
          SizedBox(height: 12),
          _buildEditableInfoCard("Name", _nameController),
          _buildEditableInfoCard("Email", _emailController, keyboardType: TextInputType.emailAddress),
          _buildEditableInfoCard("Phone Number", _phoneController, keyboardType: TextInputType.phone),
          _buildEditableDateCard("Date of Birth", _selectedDateOfBirth, () => _selectDate(context, true)),
          _buildEditableDropdownCard("Gender", _selectedGender, ['Male', 'Female', 'Other'], (value) {
            setState(() => _selectedGender = value);
          }),

          _buildSectionTitle("Academic Information"),
          SizedBox(height: 12),
          _buildEditableDateCard("Date of Admission", _selectedDateOfAdmission, () => _selectDate(context, false)),
          _buildEditableDropdownCard("Present Class", _selectedClass, ['1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th', '11th', '12th'], (value) {
            setState(() => _selectedClass = value);
          }),
          _buildEditableInfoCard("Previous School Info", _previousSchoolController, maxLines: 3),

          _buildSectionTitle("Family Information"),
          SizedBox(height: 12),
          _buildEditableInfoCard("Father's Name", _fatherNameController),
          _buildEditableInfoCard("Mother's Name", _motherNameController),

          _buildSectionTitle("Contact Information"),
          SizedBox(height: 12),
          _buildEditableInfoCard("Full Address", _addressController, maxLines: 3),
          _buildEditableInfoCard("State", _stateController),

          _buildSectionTitle("Identification Numbers"),
          SizedBox(height: 12),
          _buildEditableInfoCard("Child Aadhar Number", _childAadharController, keyboardType: TextInputType.number),
          _buildEditableInfoCard("Mother Aadhar Number", _motherAadharController, keyboardType: TextInputType.number),
          _buildEditableInfoCard("Father Aadhar Number", _fatherAadharController, keyboardType: TextInputType.number),

          _buildSectionTitle("Security"),
          SizedBox(height: 12),
          // Password change button
          Container(
            margin: EdgeInsets.only(bottom: 12),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showPasswordChangeDialog,
              icon: Icon(Icons.lock_reset, size: 20),
              label: Text('Change Password'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Save button at bottom when editing
          if (isEditing) ...[
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSavingProfile ? null : _saveProfileChanges,
                icon: isSavingProfile
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Icon(Icons.save),
                label: Text(isSavingProfile ? 'Saving...' : 'Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  // Add these methods to your ProfileScreen class

// Password change functionality


  void _showPasswordChangeDialog() {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isChangingPassword = false;
    bool showNewPassword = false;
    bool showConfirmPassword = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Get screen dimensions for responsive design
          final screenSize = MediaQuery.of(context).size;
          final isSmallScreen = screenSize.width < 600;
          final dialogWidth = isSmallScreen
              ? screenSize.width * 0.9
              : (screenSize.width * 0.8 > 500.0 ? 500.0 : screenSize.width * 0.8);

          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 8,
            child: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: screenSize.height * 0.8,
                maxWidth: 500,
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header with close button
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.lock_reset_rounded,
                              color: primaryColor,
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800] ?? Colors.grey.shade800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: isChangingPassword ? null : () => Navigator.pop(context),
                            icon: Icon(Icons.close_rounded, color: Colors.grey[600] ?? Colors.grey.shade600),
                            splashRadius: 20,
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // Subtitle
                      Text(
                        'Create a strong password to secure your account',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: Colors.grey[600] ?? Colors.grey.shade600,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 20 : 24),

                      // New Password Field
                      _buildPasswordField(
                        controller: newPasswordController,
                        label: 'New Password',
                        obscureText: !showNewPassword,
                        onVisibilityToggle: () => setDialogState(() => showNewPassword = !showNewPassword),
                        isSmallScreen: isSmallScreen,
                      ),

                      SizedBox(height: 16),

                      // Confirm Password Field
                      _buildPasswordField(
                        controller: confirmPasswordController,
                        label: 'Confirm New Password',
                        obscureText: !showConfirmPassword,
                        onVisibilityToggle: () => setDialogState(() => showConfirmPassword = !showConfirmPassword),
                        isSmallScreen: isSmallScreen,
                      ),

                      SizedBox(height: 20),

                      // Password Requirements Card
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue[50] ?? Colors.blue.shade50,
                              Colors.blue[100] ?? Colors.blue.shade100,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue[200] ?? Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.blue[700] ?? Colors.blue.shade700,
                                  size: isSmallScreen ? 16 : 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Password Requirements',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: isSmallScreen ? 12 : 13,
                                    color: Colors.blue[700] ?? Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            _buildRequirement('At least 6 characters long', isSmallScreen),
                            _buildRequirement('Include numbers and letters', isSmallScreen),
                            _buildRequirement('Avoid common passwords', isSmallScreen),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 32),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: OutlinedButton(
                              onPressed: isChangingPassword ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(color: Colors.grey[300] ?? Colors.grey.shade300),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[700] ?? Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: isChangingPassword ? null : () async {
                                // Validate passwords
                                if (newPasswordController.text.isEmpty) {
                                  _showErrorSnackBar('Please enter a new password');
                                  return;
                                }
                                if (newPasswordController.text.length < 6) {
                                  _showErrorSnackBar('New password must be at least 6 characters long');
                                  return;
                                }
                                if (!_isPasswordStrong(newPasswordController.text)) {
                                  _showErrorSnackBar('Password must contain both letters and numbers');
                                  return;
                                }
                                if (newPasswordController.text != confirmPasswordController.text) {
                                  _showErrorSnackBar('Passwords do not match');
                                  return;
                                }

                                setDialogState(() => isChangingPassword = true);

                                try {
                                  await _changePassword(newPasswordController.text);
                                  Navigator.pop(context);
                                  _showSuccessSnackBar('Password changed successfully! 🎉');
                                } catch (e) {
                                  _showErrorSnackBar('Failed to change password: ${e.toString()}');
                                } finally {
                                  setDialogState(() => isChangingPassword = false);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: primaryColor.withOpacity(0.3),
                                padding: EdgeInsets.symmetric(
                                  vertical: isSmallScreen ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isChangingPassword
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Changing...',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 14 : 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                                  : Text(
                                'Change Password',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 15,
                                  fontWeight: FontWeight.w600,
                                ),
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
          );
        },
      ),
    );
  }

// Helper method to build password input fields
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onVisibilityToggle,
    required bool isSmallScreen,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 13 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700] ?? Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(fontSize: isSmallScreen ? 14 : 15),
          decoration: InputDecoration(
            hintText: 'Enter ${label.toLowerCase()}',
            hintStyle: TextStyle(
              color: Colors.grey[400] ?? Colors.grey.shade400,
              fontSize: isSmallScreen ? 13 : 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300] ?? Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300] ?? Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isSmallScreen ? 12 : 16,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: Colors.grey[500] ?? Colors.grey.shade500,
              size: isSmallScreen ? 20 : 22,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: Colors.grey[500] ?? Colors.grey.shade500,
                size: isSmallScreen ? 20 : 22,
              ),
              onPressed: onVisibilityToggle,
              splashRadius: 20,
            ),
          ),
        ),
      ],
    );
  }

// Helper method to build requirement items
  Widget _buildRequirement(String text, bool isSmallScreen) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: Colors.blue[600] ?? Colors.blue.shade600,
            size: isSmallScreen ? 14 : 16,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                color: Colors.blue[600] ?? Colors.blue.shade600,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Helper method to validate password strength
  bool _isPasswordStrong(String password) {
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    return hasLetter && hasNumber;
  }
  Future<void> _changePassword(String newPassword) async {
    try {
      print('=== PASSWORD CHANGE DEBUG ===');
      print('User ID: ${widget.userId}');
      print('Change Password URL: $BASE_URL/users/user/${widget.userId}/change-password');

      final response = await http.put(
        Uri.parse('$BASE_URL/users/user/${widget.userId}/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'new_password': newPassword,
        }),
      );

      print('=== PASSWORD CHANGE RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Password change successful: ${responseData['message']}');
      } else {
        String errorMessage;
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? 'Password change failed';
        } catch (e) {
          errorMessage = 'Server error (${response.statusCode})';
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('=== PASSWORD CHANGE ERROR ===');
      print('Exception: $e');
      rethrow;
    }
  }
  Widget _buildInfoCard(String title, String value) {
    final val = value.trim();
    if (val.isEmpty || val.toLowerCase() == 'n/a' || val.toLowerCase() == 'not available') {
      return SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500, fontSize: 14)),
          SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Documents & Registration',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
          ),
          SizedBox(height: 16),
          _buildRegistrationNumbersCard(),
          SizedBox(height: 20),
          _buildDocumentManagementSection(),
        ],
      ),
    );
  }

  Widget _buildRegistrationNumbersCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.numbers, color: primaryColor, size: 24),
              SizedBox(width: 12),
              Text('Registration Numbers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _srnController,
            decoration: InputDecoration(
              labelText: 'SRN Number',
              hintText: 'Enter your SRN number',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: Icon(Icons.confirmation_number),
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _penController,
            decoration: InputDecoration(
              labelText: 'PEN Number',
              hintText: 'Enter your PEN number',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: Icon(Icons.badge),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isUploading ? null : _updateNumbers,
              icon: isUploading
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Icon(Icons.save),
              label: Text(isUploading ? 'Updating...' : 'Update Numbers'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentManagementSection() {
    final docTypes = [
      {'key': 'birth_certificate', 'title': 'Birth Certificate', 'icon': Icons.assignment_ind},
      {'key': 'student_adhaar_card', 'title': 'Student Aadhaar Card', 'icon': Icons.credit_card},
      {'key': 'father_adhaar_card', 'title': 'Father\'s Aadhaar Card', 'icon': Icons.credit_card},
      {'key': 'mother_adhaar_card', 'title': 'Mother\'s Aadhaar Card', 'icon': Icons.credit_card},
      {'key': 'previous_school_marksheet', 'title': 'Previous School Marksheet', 'icon': Icons.school},
      {'key': 'school_leaving_certificate', 'title': 'School Leaving Certificate', 'icon': Icons.description},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Document Management', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)),
        SizedBox(height: 16),
        for (var docType in docTypes) _buildDocumentItem(docType),
      ],
    );
  }

  Widget _buildDocumentItem(Map<String, dynamic> docType) {
    String key = docType['key'];
    String title = docType['title'];
    IconData icon = docType['icon'];
    bool hasDocument = documentsData?[key] != null && documentsData![key].toString().isNotEmpty;
    String? documentUrl = documentsData?[key];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: hasDocument ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2), width: 1),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
      Row(
      children: [
      Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasDocument ? Colors.green.withOpacity(0.1) : primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: hasDocument ? Colors.green : primaryColor, size: 24),
    ),
    SizedBox(width: 16),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
    SizedBox(height: 4),
    Text(
    hasDocument ? 'Document uploaded' : 'Not uploaded',
    style: TextStyle(fontSize: 12, color: hasDocument ? Colors.green : Colors.grey[500]),
    ),
    ],
    ),
    ),
    if (hasDocument)
    Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
    child: Text('Uploaded', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w500)),
    ),
    ],
    ),
    SizedBox(height: 16),
    Row(
    children: [
    Expanded(
    child: ElevatedButton.icon(
    onPressed: isUploading ? null : () => _uploadDocument(key, title),
    icon: isUploading
    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
        : Icon(Icons.cloud_upload, size: 18),
    label: Text(isUploading ? 'Uploading...' : 'Upload'),
    style: ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    ),
    ),
    if (hasDocument) ...[
    SizedBox(width: 12),
    Expanded(
    child: ElevatedButton.icon(
    onPressed: () => _viewDocument(documentUrl, title),
      icon: Icon(Icons.visibility, size: 18),
      label: Text('View'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    ),
    ],
    ],
    ),
          ],
      ),
    );
  }
  Widget _buildReadOnlyInfoCard(String title, String value, {String? subtitle}) {
    final val = value.trim();
    if (val.isEmpty || val.toLowerCase() == 'n/a' || val.toLowerCase() == 'not available') {
      return SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100], // Different background to indicate read-only
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2))
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: TextStyle(color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 14)),
              ),
              Icon(Icons.lock_outline, color: Colors.grey[500], size: 16),
            ],
          ),
          SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w600)),
          if (subtitle != null) ...[
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 4),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
    );
  }


}