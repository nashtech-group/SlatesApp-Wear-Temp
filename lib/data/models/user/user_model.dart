// lib/data/models/user_model.dart
import 'package:slates_app_wear/data/models/customer/customer_model.dart';

class UserModel {
  final int id;
  final String employeeId;
  final int customerId;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String mobileNumber;
  final DateTime employmentDate;
  final String streetAddress;
  final String city;
  final String state;
  final String country;
  final DateTime dateOfBirth;
  final String gender;
  final String jobTitle;
  final String department;
  final String profilePhotoUrl;
  final String nextOfKin;
  final String emergencyContact;
  final String? rank;
  final String workMode;
  final String contractType;
  final String nationalId;
  final String passportNumber;
  final int createdBy;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CustomerModel customer;

  UserModel({
    required this.id,
    required this.employeeId,
    required this.customerId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.mobileNumber,
    required this.employmentDate,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.country,
    required this.dateOfBirth,
    required this.gender,
    required this.jobTitle,
    required this.department,
    required this.profilePhotoUrl,
    required this.nextOfKin,
    required this.emergencyContact,
    this.rank,
    required this.workMode,
    required this.contractType,
    required this.nationalId,
    required this.passportNumber,
    required this.createdBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.customer,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      employeeId: json['employeeId'] ?? '',
      customerId: json['customerId'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      employmentDate: DateTime.parse(json['employmentDate'] ?? DateTime.now().toIso8601String()),
      streetAddress: json['streetAddress'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      dateOfBirth: DateTime.parse(json['dateOfBirth'] ?? DateTime.now().toIso8601String()),
      gender: json['gender'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      department: json['department'] ?? '',
      profilePhotoUrl: json['profilePhotoUrl'] ?? '',
      nextOfKin: json['nextOfKin'] ?? '',
      emergencyContact: json['emergencyContact'] ?? '',
      rank: json['rank'],
      workMode: json['workMode'] ?? '',
      contractType: json['contractType'] ?? '',
      nationalId: json['nationalId'] ?? '',
      passportNumber: json['passportNumber'] ?? '',
      createdBy: json['createdBy'] ?? 0,
      status: json['status'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      customer: CustomerModel.fromJson(json['customer'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'customerId': customerId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'role': role,
      'mobileNumber': mobileNumber,
      'employmentDate': employmentDate.toIso8601String(),
      'streetAddress': streetAddress,
      'city': city,
      'state': state,
      'country': country,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'jobTitle': jobTitle,
      'department': department,
      'profilePhotoUrl': profilePhotoUrl,
      'nextOfKin': nextOfKin,
      'emergencyContact': emergencyContact,
      'rank': rank,
      'workMode': workMode,
      'contractType': contractType,
      'nationalId': nationalId,
      'passportNumber': passportNumber,
      'createdBy': createdBy,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'customer': customer.toJson(),
    };
  }

  // Helper getters
  String get fullName => '$firstName $lastName'.trim();
  String get initials => '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase();
  bool get isActive => status.toLowerCase() == 'active';
  bool get isGuard => role.toLowerCase() == 'guard';
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isManager => role.toLowerCase() == 'manager';
  
  // Role access helpers
  bool get hasAdminAccess => isAdmin || isManager;
  bool get hasGuardAccess => isGuard;
  
  String get displayRole {
    switch (role.toLowerCase()) {
      case 'guard':
        return 'Security Guard';
      case 'admin':
        return 'Administrator';
      case 'manager':
        return 'Manager';
      default:
        return role.replaceAll('-', ' ').split(' ')
            .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
            .join(' ');
    }
  }

  String get formattedEmploymentDate {
    return '${employmentDate.day}/${employmentDate.month}/${employmentDate.year}';
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  UserModel copyWith({
    int? id,
    String? employeeId,
    int? customerId,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    String? mobileNumber,
    DateTime? employmentDate,
    String? streetAddress,
    String? city,
    String? state,
    String? country,
    DateTime? dateOfBirth,
    String? gender,
    String? jobTitle,
    String? department,
    String? profilePhotoUrl,
    String? nextOfKin,
    String? emergencyContact,
    String? rank,
    String? workMode,
    String? contractType,
    String? nationalId,
    String? passportNumber,
    int? createdBy,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    CustomerModel? customer,
  }) {
    return UserModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      customerId: customerId ?? this.customerId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      employmentDate: employmentDate ?? this.employmentDate,
      streetAddress: streetAddress ?? this.streetAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      jobTitle: jobTitle ?? this.jobTitle,
      department: department ?? this.department,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      nextOfKin: nextOfKin ?? this.nextOfKin,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      rank: rank ?? this.rank,
      workMode: workMode ?? this.workMode,
      contractType: contractType ?? this.contractType,
      nationalId: nationalId ?? this.nationalId,
      passportNumber: passportNumber ?? this.passportNumber,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customer: customer ?? this.customer,
    );
  }
}