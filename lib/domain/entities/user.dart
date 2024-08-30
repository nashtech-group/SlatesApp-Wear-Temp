import 'package:slates_app_wear/domain/entities/authorization.dart';

class User {
  final int id;
  final String employeeId;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String? mobileNumber;
  final String? employmentDate;
  final String status;
  final int customerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Authorization authorization;

  User({
    required this.id,
    required this.employeeId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.mobileNumber,
    this.employmentDate,
    required this.status,
    required this.customerId,
    required this.createdAt,
    required this.updatedAt,
    required this.authorization,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      employeeId: json['employeeId'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      role: json['role'],
      mobileNumber: json['mobileNumber'],
      employmentDate: json['employmentDate'],
      status: json['status'],
      customerId: json['customerId'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      authorization: Authorization.fromJson(json),
    );
  }

  // Convert User to JSON 
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employeeId': employeeId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'mobileNumber': mobileNumber,
      'employmentDate': employmentDate,
      'status': status,
      'customerId': customerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'authorization': authorization.toJson(),
    };
  }
}

