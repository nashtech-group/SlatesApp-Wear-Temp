import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slates_app_wear/core/constants/api_constants.dart';
import 'package:slates_app_wear/core/error/provider_error_mixin.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_request_model.dart';

class RosterProvider with ProviderErrorMixin {
  final http.Client client;

  RosterProvider({http.Client? client}) : client = client ?? http.Client();

  /// Get roster data for a guard from a specific date
  Future<String> getRosterData({
    required int guardId,
    required String fromDate,
    required String token,
  }) async {
    const operation = 'getRosterData';
    
    // Build query parameters
    final queryParams = {
      'guardId[eq]': guardId.toString(),
      'initialShiftDate[gte]': fromDate,
    };

    // Build URI with query parameters
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.rosterEndpoint}/guards')
        .replace(queryParameters: queryParams);

    logHttpRequest('GET', uri.toString(), buildStandardHeaders(token: token));

    final response = await safeHttpCallWithTimeout(
      () => client.get(uri, headers: buildStandardHeaders(token: token)),
      operation,
    );

    logHttpResponse(response, operation);
    return extractResponseBody(response, operation);
  }

  /// Submit comprehensive guard duty data
  Future<String> submitComprehensiveGuardDuty({
    required ComprehensiveGuardDutyRequestModel requestData,
    required String token,
  }) async {
    const operation = 'submitComprehensiveGuardDuty';
    
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.comprehensiveGuardDutyEndpoint}');
    final headers = buildPostHeaders(token: token);
    
    logHttpRequest('PATCH', uri.toString(), headers);

    final response = await safeHttpCallWithTimeout(
      () => client.patch(
        uri,
        headers: headers,
        body: jsonEncode(requestData.toJson()),
      ),
      operation,
      customTimeout: getTimeoutForOperation('upload'),
    );

    logHttpResponse(response, operation);
    return extractResponseBody(response, operation);
  }

  /// Get roster data with pagination support
  Future<String> getRosterDataPaginated({
    required int guardId,
    required String fromDate,
    required String token,
    int page = 1,
    int perPage = 15,
  }) async {
    const operation = 'getRosterDataPaginated';
    
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

    logHttpRequest('GET', uri.toString(), buildStandardHeaders(token: token));

    final response = await safeHttpCallWithTimeout(
      () => client.get(uri, headers: buildStandardHeaders(token: token)),
      operation,
    );

    logHttpResponse(response, operation);
    return extractResponseBody(response, operation);
  }

  /// Get roster data for multiple guards (bulk fetch)
  Future<String> getBulkRosterData({
    required List<int> guardIds,
    required String fromDate,
    required String token,
  }) async {
    const operation = 'getBulkRosterData';
    
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

    logHttpRequest('GET', uri.toString(), buildStandardHeaders(token: token));

    final response = await safeHttpCallWithTimeout(
      () => client.get(uri, headers: buildStandardHeaders(token: token)),
      operation,
    );

    logHttpResponse(response, operation);
    return extractResponseBody(response, operation);
  }

  /// Get roster data for a specific date range
  Future<String> getRosterDataForDateRange({
    required int guardId,
    required String fromDate,
    required String toDate,
    required String token,
  }) async {
    const operation = 'getRosterDataForDateRange';
    
    // Build query parameters
    final queryParams = {
      'guardId[eq]': guardId.toString(),
      'initialShiftDate[gte]': fromDate,
      'initialShiftDate[lte]': toDate,
    };

    // Build URI with query parameters
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.rosterEndpoint}/guards')
        .replace(queryParameters: queryParams);

    logHttpRequest('GET', uri.toString(), buildStandardHeaders(token: token));

    final response = await safeHttpCallWithTimeout(
      () => client.get(uri, headers: buildStandardHeaders(token: token)),
      operation,
    );

    logHttpResponse(response, operation);
    return extractResponseBody(response, operation);
  }

  /// Get current roster status for today's duties
  Future<String> getTodaysRosterStatus({
    required int guardId,
    required String token,
  }) async {
    // Get today's date in the required format
    final today = DateTime.now();
    final formattedDate = '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';

    return await getRosterData(
      guardId: guardId,
      fromDate: formattedDate,
      token: token,
    );
  }

  /// Get upcoming roster duties (next 7 days)
  Future<String> getUpcomingRosterDuties({
    required int guardId,
    required String token,
  }) async {
    // Get today's date in the required format
    final today = DateTime.now();
    final formattedDate = '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';

    return await getRosterData(
      guardId: guardId,
      fromDate: formattedDate,
      token: token,
    );
  }
}