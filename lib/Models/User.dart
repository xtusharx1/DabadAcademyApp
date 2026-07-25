
class User {
  final int userId;
  final int roleId;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profilePicture;
  final String passwordHash;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? dateOfAdmission;
  final String? presentClass;
  final DateTime? dateOfBirth;
  final double? totalCourseFees;
  final String? fatherName;
  final String? motherName;
  final String? fullAddress;
  final String? childAadharNumber;
  final String? motherAadharNumber;
  final String? fatherAadharNumber;
  final String? permanentEducationNumber;
  final String? studentRegistrationNumber;
  final String? previousSchoolInfo;
  final String? gender;
  final String? state;

  // Constructor to initialize the object
  User({
    required this.userId,
    required this.roleId,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profilePicture,
    required this.passwordHash,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.dateOfAdmission,
    this.presentClass,
    this.dateOfBirth,
    this.totalCourseFees,
    this.fatherName,
    this.motherName,
    this.fullAddress,
    this.childAadharNumber,
    this.motherAadharNumber,
    this.fatherAadharNumber,
    this.permanentEducationNumber,
    this.studentRegistrationNumber,
    this.previousSchoolInfo,
    this.gender,
    this.state,
  });

  // Factory method to create a User object from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      roleId: json['role_id'],
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      profilePicture: json['profile_picture'],
      passwordHash: json['password_hash'],
      status: json['status'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      dateOfAdmission: json['date_of_admission'] != null ? DateTime.parse(json['date_of_admission']) : null,
      presentClass: json['present_class'],
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      totalCourseFees: json['total_course_fees']?.toDouble(),
      fatherName: json['father_name'],
      motherName: json['mother_name'],
      fullAddress: json['full_address'],
      childAadharNumber: json['child_aadhar_number'],
      motherAadharNumber: json['mother_aadhar_number'],
      fatherAadharNumber: json['father_aadhar_number'],
      permanentEducationNumber: json['permanent_education_number'],
      studentRegistrationNumber: json['student_registration_number'],
      previousSchoolInfo: json['previous_school_info'],
      gender: json['gender'],
      state: json['state'],
    );
  }

  // Method to convert the User object into a JSON map
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'role_id': roleId,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'profile_picture': profilePicture,
      'password_hash': passwordHash,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'date_of_admission': dateOfAdmission?.toIso8601String(),
      'present_class': presentClass,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'total_course_fees': totalCourseFees,
      'father_name': fatherName,
      'mother_name': motherName,
      'full_address': fullAddress,
      'child_aadhar_number': childAadharNumber,
      'mother_aadhar_number': motherAadharNumber,
      'father_aadhar_number': fatherAadharNumber,
      'permanent_education_number': permanentEducationNumber,
      'student_registration_number': studentRegistrationNumber,
      'previous_school_info': previousSchoolInfo,
      'gender': gender,
      'state': state,
    };
  }
}

