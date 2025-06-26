class LoginModel {
  final String identifier; // employeeId for guards, email for admin/manager
  final String password;   // 4-digit PIN

  LoginModel({
    required this.identifier,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'identifier': identifier,
      'password': password,
    };
  }

  factory LoginModel.fromJson(Map<String, dynamic> json) {
    return LoginModel(
      identifier: json['identifier'] ?? '',
      password: json['password'] ?? '',
    );
  }

  @override
  String toString() {
    return 'LoginModel(identifier: $identifier, password: [HIDDEN])';
  }

  bool isValid() {
    return identifier.isNotEmpty && password.isNotEmpty;
  }

  LoginModel copyWith({
    String? identifier,
    String? password,
  }) {
    return LoginModel(
      identifier: identifier ?? this.identifier,
      password: password ?? this.password,
    );
  }
}