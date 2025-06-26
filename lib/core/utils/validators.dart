class Validators {
  /// Employee ID validation for guards (format: ABC-123)
  static String? employeeId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Employee ID is required';
    }

    if (value.length > 20) {
      return 'Employee ID too long';
    }

    // Guard employee ID format: 3 letters, dash, 3 numbers
    final idRegex = RegExp(r'^[A-Z]{3}-\d{3}$');
    if (!idRegex.hasMatch(value.toUpperCase())) {
      return 'Format: ABC-123';
    }

    return null;
  }

  /// Email validation for admin/manager
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Invalid email';
    }

    return null;
  }

  /// PIN validation (4 digits)
  static String? pin(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }

    if (value.length != 4) {
      return 'PIN must be 4 digits';
    }

    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return 'PIN must be numbers only';
    }

    return null;
  }

  /// Required field validation
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName required';
    }
    return null;
  }

  /// Determine login type based on identifier
  static LoginType getLoginType(String identifier) {
    if (identifier.contains('@')) {
      return LoginType.email;
    } else if (RegExp(r'^[A-Z]{3}-\d{3}$').hasMatch(identifier.toUpperCase())) {
      return LoginType.employeeId;
    } else {
      return LoginType.unknown;
    }
  }
}

enum LoginType {
  email,
  employeeId,
  unknown,
}
