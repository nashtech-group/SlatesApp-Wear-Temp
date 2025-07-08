
import 'package:equatable/equatable.dart';

class SyncResult extends Equatable {
  /// Whether the sync operation was successful
  final bool success;
  
  /// Human-readable message describing the result
  final String message;
  
  /// Number of items successfully synced
  final int successCount;
  
  /// Number of items that failed to sync
  final int failureCount;
  
  /// List of error messages for failed items
  final List<String> errors;
  
  /// Additional metadata about the sync operation
  /// Common keys: 'sync_duration_ms', 'total_submissions', 'reason'
  final Map<String, dynamic> metadata;

  const SyncResult({
    required this.success,
    required this.message,
    required this.successCount,
    required this.failureCount,
    this.errors = const [],
    this.metadata = const {},
  });

  /// Create a successful sync result
  factory SyncResult.success({
    required String message,
    required int successCount,
    int failureCount = 0,
    Map<String, dynamic> metadata = const {},
  }) {
    return SyncResult(
      success: true,
      message: message,
      successCount: successCount,
      failureCount: failureCount,
      metadata: metadata,
    );
  }

  /// Create a failed sync result
  factory SyncResult.failure({
    required String message,
    int successCount = 0,
    int failureCount = 1,
    List<String> errors = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    return SyncResult(
      success: false,
      message: message,
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
      metadata: metadata,
    );
  }

  /// Create a partial success result (some items succeeded, some failed)
  factory SyncResult.partial({
    required String message,
    required int successCount,
    required int failureCount,
    List<String> errors = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    return SyncResult(
      success: false, // Partial success is considered failure for safety
      message: message,
      successCount: successCount,
      failureCount: failureCount,
      errors: errors,
      metadata: metadata,
    );
  }

  /// Total number of items processed
  int get totalCount => successCount + failureCount;
  
  /// Whether there are any error messages
  bool get hasErrors => errors.isNotEmpty;
  
  /// Success rate as a percentage (0.0 to 1.0)
  double get successRate => totalCount > 0 ? successCount / totalCount : 0.0;
  
  /// Success rate as a percentage (0 to 100)
  int get successPercentage => (successRate * 100).round();
  
  /// Whether this was a complete success (all items synced)
  bool get isCompleteSuccess => success && failureCount == 0;
  
  /// Whether this was a complete failure (no items synced)
  bool get isCompleteFailure => !success && successCount == 0;
  
  /// Whether this was a partial success (some items synced)
  bool get isPartialSuccess => successCount > 0 && failureCount > 0;

  /// Get sync duration from metadata if available
  Duration? get syncDuration {
    final durationMs = metadata['sync_duration_ms'] as int?;
    return durationMs != null ? Duration(milliseconds: durationMs) : null;
  }

  /// Get formatted sync duration string
  String get formattedDuration {
    final duration = syncDuration;
    if (duration == null) return 'Unknown';
    
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${minutes}m ${seconds}s';
    }
  }

  /// Create a copy with updated values
  SyncResult copyWith({
    bool? success,
    String? message,
    int? successCount,
    int? failureCount,
    List<String>? errors,
    Map<String, dynamic>? metadata,
  }) {
    return SyncResult(
      success: success ?? this.success,
      message: message ?? this.message,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      errors: errors ?? this.errors,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for logging/storage
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'success_count': successCount,
      'failure_count': failureCount,
      'total_count': totalCount,
      'success_rate': successRate,
      'errors': errors,
      'metadata': metadata,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Create from JSON
  factory SyncResult.fromJson(Map<String, dynamic> json) {
    return SyncResult(
      success: json['success'] as bool,
      message: json['message'] as String,
      successCount: json['success_count'] as int,
      failureCount: json['failure_count'] as int,
      errors: List<String>.from(json['errors'] as List),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
    );
  }

  @override
  List<Object?> get props => [
        success,
        message,
        successCount,
        failureCount,
        errors,
        metadata,
      ];

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('SyncResult(');
    buffer.write('success: $success, ');
    buffer.write('message: "$message", ');
    buffer.write('success: $successCount, ');
    buffer.write('failures: $failureCount');
    
    if (hasErrors) {
      buffer.write(', errors: ${errors.length}');
    }
    
    final duration = syncDuration;
    if (duration != null) {
      buffer.write(', duration: $formattedDuration');
    }
    
    buffer.write(')');
    return buffer.toString();
  }
}