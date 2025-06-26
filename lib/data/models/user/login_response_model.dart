// lib/data/models/login_response_model.dart
import 'package:slates_app_wear/data/models/user/user_model.dart';

class LoginResponseModel {
  final String status;
  final String message;
  final UserModel user;
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  LoginResponseModel({
    required this.status,
    required this.message,
    required this.user,
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
      accessToken: json['accessToken'] ?? '',
      tokenType: json['tokenType'] ?? 'Bearer',
      expiresIn: json['expiresIn'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'user': user.toJson(),
      'accessToken': accessToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
    };
  }

  // Helper getters
  bool get isSuccess => status.toLowerCase() == 'success';
  String get authorizationHeader => '$tokenType $accessToken';
  
  DateTime get expiresAt {
    return DateTime.now().add(Duration(seconds: expiresIn));
  }
  
  bool get isTokenExpired {
    return DateTime.now().isAfter(expiresAt);
  }
  
  Duration get timeUntilExpiry {
    final expiry = expiresAt;
    final now = DateTime.now();
    if (now.isAfter(expiry)) {
      return Duration.zero;
    }
    return expiry.difference(now);
  }

  LoginResponseModel copyWith({
    String? status,
    String? message,
    UserModel? user,
    String? accessToken,
    String? tokenType,
    int? expiresIn,
  }) {
    return LoginResponseModel(
      status: status ?? this.status,
      message: message ?? this.message,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      tokenType: tokenType ?? this.tokenType,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }
}