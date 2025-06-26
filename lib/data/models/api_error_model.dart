class ApiErrorModel implements Exception {
  final String status;
  final String message;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  ApiErrorModel({
    required this.status,
    required this.message,
    this.errors,
    this.statusCode,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    return ApiErrorModel(
      status: json['status'] ?? 'error',
      message: json['message'] ?? 'An unknown error occurred',
      errors: json['errors'],
      statusCode: json['statusCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'errors': errors,
      'statusCode': statusCode,
    };
  }

  @override
  String toString() {
    return 'ApiErrorModel(status: $status, message: $message, statusCode: $statusCode)';
  }

  bool get hasValidationErrors => errors != null && errors!.isNotEmpty;
  
  List<String> get validationMessages {
    if (!hasValidationErrors) return [];
    
    List<String> messages = [];
    errors!.forEach((field, fieldErrors) {
      if (fieldErrors is List) {
        messages.addAll(fieldErrors.cast<String>());
      } else if (fieldErrors is String) {
        messages.add(fieldErrors);
      }
    });
    return messages;
  }
}