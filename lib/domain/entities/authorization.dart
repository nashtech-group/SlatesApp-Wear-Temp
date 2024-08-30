// domain/entities/authorization.dart
class Authorization {
  final String accessToken;
  final String tokenType;
  final int expiresIn;
  final DateTime issuedAt;

  Authorization({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.issuedAt,
  });

  factory Authorization.fromJson(Map<String, dynamic> json) {
    return Authorization(
      accessToken: json['accessToken'],
      tokenType: json['tokenType'],
      expiresIn: json['expiresIn'],
      issuedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
      'issuedAt': issuedAt.toIso8601String(),
    };
  }

  bool isTokenValid() {
    final expiryDate = issuedAt.add(Duration(seconds: expiresIn));
    return DateTime.now().isBefore(expiryDate);
  }
}
