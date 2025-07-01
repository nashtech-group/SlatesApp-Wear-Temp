import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:slates_app_wear/core/constants/api_constants.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_request_model.dart';

class RosterProvider {
  final http.Client client;

  RosterProvider({http.Client? client}) : client = client ?? http.Client();

  /// Get roster data for a guard from a specific date
  /// Parameters:
  /// - guardId: The ID of the guard
  /// - fromDate: The date from which to fetch roster data (format: dd-MM-yyyy)
  /// - token: Bearer authentication token
  Future<String> getRosterData({
    required int guardId,
    required String fromDate,
    required String token,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'guardId[eq]': guardId.toString(),
        'initialShiftDate[gte]': fromDate,
      };

      // Build URI with query parameters
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.rosterEndpoint}/guards')
          .replace(queryParameters: queryParams);

      final response = await client
          .get(
            uri,
            headers: {
              ApiConstants.acceptHeader: ApiConstants.contentType,
              ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix}$token',
            },
          )
          .timeout(
            const Duration(seconds: ApiConstants.timeoutDuration),
          );

      return response.body;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  /// Submit comprehensive guard duty data (roster updates, movements, perimeter checks)
  /// Parameters:
  /// - requestData: The comprehensive guard duty request model containing updates, movements, and perimeter checks
  /// - token: Bearer authentication token
  Future<String> submitComprehensiveGuardDuty({
    required ComprehensiveGuardDutyRequestModel requestData,
    required String token,
  }) async {
    try {
      final response = await client
          .patch(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.comprehensiveGuardDutyEndpoint}'),
            headers: {
              ApiConstants.acceptHeader: ApiConstants.contentType,
              ApiConstants.contentTypeHeader: ApiConstants.contentType,
              ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix}$token',
            },
            body: jsonEncode(requestData.toJson()),
          )
          .timeout(
            const Duration(seconds: ApiConstants.timeoutDuration),
          );

      return response.body;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  /// Get roster data with pagination support
  /// Parameters:
  /// - guardId: The ID of the guard
  /// - fromDate: The date from which to fetch roster data (format: dd-MM-yyyy)
  /// - token: Bearer authentication token
  /// - page: Page number for pagination (optional, defaults to 1)
  /// - perPage: Number of items per page (optional, defaults to 15)
  Future<String> getRosterDataPaginated({
    required int guardId,
    required String fromDate,
    required String token,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'guardId[eq]': guardId.toString(),
        'initialShiftDate[gte]': fromDate,
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      // Build URI with query parameters
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.rosterEndpoint}/guards')
          .replace(queryParameters: queryParams);

      final response = await client
          .get(
            uri,
            headers: {
              ApiConstants.acceptHeader: ApiConstants.contentType,
              ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix}$token',
            },
          )
          .timeout(
            const Duration(seconds: ApiConstants.timeoutDuration),
          );

      return response.body;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  /// Get roster data for multiple guards (bulk fetch)
  /// Parameters:
  /// - guardIds: List of guard IDs
  /// - fromDate: The date from which to fetch roster data (format: dd-MM-yyyy)
  /// - token: Bearer authentication token
  Future<String> getBulkRosterData({
    required List<int> guardIds,
    required String fromDate,
    required String token,
  }) async {
    try {
      // Build query parameters for multiple guard IDs
      final queryParams = <String, String>{
        'initialShiftDate[gte]': fromDate,
      };

      // Add multiple guardId parameters
      for (int i = 0; i < guardIds.length; i++) {
        queryParams['guardId[$i]'] = guardIds[i].toString();
      }

      // Build URI with query parameters
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.rosterEndpoint}/guards')
          .replace(queryParameters: queryParams);

      final response = await client
          .get(
            uri,
            headers: {
              ApiConstants.acceptHeader: ApiConstants.contentType,
              ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix}$token',
            },
          )
          .timeout(
            const Duration(seconds: ApiConstants.timeoutDuration),
          );

      return response.body;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  /// Get roster data for a specific date range
  /// Parameters:
  /// - guardId: The ID of the guard
  /// - fromDate: Start date (format: dd-MM-yyyy)
  /// - toDate: End date (format: dd-MM-yyyy)
  /// - token: Bearer authentication token
  Future<String> getRosterDataForDateRange({
    required int guardId,
    required String fromDate,
    required String toDate,
    required String token,
  }) async {
    try {
      // Build query parameters
      final queryParams = {
        'guardId[eq]': guardId.toString(),
        'initialShiftDate[gte]': fromDate,
        'initialShiftDate[lte]': toDate,
      };

      // Build URI with query parameters
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.rosterEndpoint}/guards')
          .replace(queryParameters: queryParams);

      final response = await client
          .get(
            uri,
            headers: {
              ApiConstants.acceptHeader: ApiConstants.contentType,
              ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix}$token',
            },
          )
          .timeout(
            const Duration(seconds: ApiConstants.timeoutDuration),
          );

      return response.body;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  /// Submit batch of roster user status updates only
  /// Parameters:
  /// - updates: List of roster user updates
  /// - token: Bearer authentication token
  Future<String> submitRosterUserUpdates({
    required List<Map<String, dynamic>> updates,
    required String token,
  }) async {
    try {
      final requestData = {
        'updates': updates,
      };

      final response = await client
          .patch(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.comprehensiveGuardDutyEndpoint}'),
            headers: {
              ApiConstants.acceptHeader: ApiConstants.contentType,
              ApiConstants.contentTypeHeader: ApiConstants.contentType,
              ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix}$token',
            },
            body: jsonEncode(requestData),
          )
          .timeout(
            const Duration(seconds: ApiConstants.timeoutDuration),
          );

      return response.body;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  /// Submit batch of guard movements only
  /// Parameters:
  /// - movements: List of guard movements
  /// - token: Bearer authentication token
  Future<String> submitGuardMovements({
    required List<Map<String, dynamic>> movements,
    required String token,
  }) async {
    try {
      final requestData = {
        'movements': movements,
      };

      final response = await client
          .patch(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.comprehensiveGuardDutyEndpoint}'),
            headers: {
              ApiConstants.acceptHeader: ApiConstants.contentType,
              ApiConstants.contentTypeHeader: ApiConstants.contentType,
              ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix}$token',
            },
            body: jsonEncode(requestData),
          )
          .timeout(
            const Duration(seconds: ApiConstants.timeoutDuration),
          );

      return response.body;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  /// Submit batch of perimeter checks only
  /// Parameters:
  /// - perimeterChecks: List of perimeter checks
  /// - token: Bearer authentication token
  Future<String> submitPerimeterChecks({
    required List<Map<String, dynamic>> perimeterChecks,
    required String token,
  }) async {
    try {
      final requestData = {
        'perimeterChecks': perimeterChecks,
      };

      final response = await client
          .patch(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.comprehensiveGuardDutyEndpoint}'),
            headers: {
              ApiConstants.acceptHeader: ApiConstants.contentType,
              ApiConstants.contentTypeHeader: ApiConstants.contentType,
              ApiConstants.authorizationHeader: '${ApiConstants.bearerPrefix}$token',
            },
            body: jsonEncode(requestData),
          )
          .timeout(
            const Duration(seconds: ApiConstants.timeoutDuration),
          );

      return response.body;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  /// Get current roster status for today's duties
  /// Parameters:
  /// - guardId: The ID of the guard
  /// - token: Bearer authentication token
  Future<String> getTodaysRosterStatus({
    required int guardId,
    required String token,
  }) async {
    try {
      // Get today's date in the required format
      final today = DateTime.now();
      final formattedDate = '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';

      return await getRosterData(
        guardId: guardId,
        fromDate: formattedDate,
        token: token,
      );
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  /// Get upcoming roster duties (next 7 days)
  /// Parameters:
  /// - guardId: The ID of the guard
  /// - token: Bearer authentication token
  Future<String> getUpcomingRosterDuties({
    required int guardId,
    required String token,
  }) async {
    try {
      // Get today's date in the required format
      final today = DateTime.now();
      final formattedDate = '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';

      return await getRosterData(
        guardId: guardId,
        fromDate: formattedDate,
        token: token,
      );
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }
}