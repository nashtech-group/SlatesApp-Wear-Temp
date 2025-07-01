import 'package:slates_app_wear/data/models/roster/guard_duty_summary_model.dart';

class ComprehensiveGuardDutyResponseModel {
  final String message;
  final GuardDutySummaryModel summary;
  final DateTime timestamp;

  ComprehensiveGuardDutyResponseModel({
    required this.message,
    required this.summary,
    required this.timestamp,
  });

  factory ComprehensiveGuardDutyResponseModel.fromJson(Map<String, dynamic> json) {
    return ComprehensiveGuardDutyResponseModel(
      message: json['message'] ?? '',
      summary: GuardDutySummaryModel.fromJson(json['summary'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'summary': summary.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  bool get isSuccess => message.toLowerCase().contains('success');

  ComprehensiveGuardDutyResponseModel copyWith({
    String? message,
    GuardDutySummaryModel? summary,
    DateTime? timestamp,
  }) {
    return ComprehensiveGuardDutyResponseModel(
      message: message ?? this.message,
      summary: summary ?? this.summary,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
