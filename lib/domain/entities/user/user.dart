import 'package:slates_app_wear/domain/entities/user/authorization.dart';

class User {
  final int? id;
  final String? employeeId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? role;
  final String? mobileNumber;
  final DateTime? employmentDate;
  final String? status;
  final int? customerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Authorization authorization;

  User({
    this.id,
    this.employeeId,
    this.email,
    this.firstName,
    this.lastName,
    this.role,
    this.mobileNumber,
    this.employmentDate,
    this.status,
    this.customerId,
    this.createdAt,
    this.updatedAt,
    required this.authorization,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] != null ? json['id'] as int : null,
      employeeId: json['employeeId'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      role: json['role'] ?? '',
      mobileNumber:
          json['mobileNumber'] != null ? json['mobileNumber'] as String : '',
      employmentDate: json['employmentDate'] != null
          ? DateTime.parse(json['employmentDate'])
          : null,
      status: json['status'] ?? '',
      customerId: json['customerId'] != null ? json['customerId'] as int : null,
      createdAt: json["created_at"] == null
          ? null
          : DateTime.parse(json["created_at"]),
      updatedAt: json["updated_at"] == null
          ? null
          : DateTime.parse(json["updated_at"]),
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
      'employmentDate': employmentDate?.toIso8601String(),
      'status': status,
      'customerId': customerId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'authorization': authorization.toJson(),
    };
  }
}
