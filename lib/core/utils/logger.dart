import 'dart:developer' as developer;

class Logger {
  static void log(String message, {String? tag}) {
    final logTag = tag ?? 'APP_LOG';
    developer.log(message, name: logTag);
  }

  static void error(String message, {String? tag}) {
    final logTag = tag ?? 'APP_ERROR';
    developer.log('ERROR: $message', name: logTag);
  }
}
