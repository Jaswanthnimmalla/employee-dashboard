import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:employee_dashboard_app/core/utils/app_exceptions.dart';
import 'api_endpoints.dart'; // Correct relative import

class ApiClient {
  final http.Client _client;

  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final response = await _client
          .post(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));

      return _processResponse(response);
    } catch (e) {
      throw AppExceptions.handleError(e);
    }
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _client
          .get(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return _processResponse(response);
    } catch (e) {
      throw AppExceptions.handleError(e);
    }
  }

  Future<dynamic> put(String endpoint, {Map<String, dynamic>? data}) async {
    try {
      final response = await _client
          .put(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: _getHeaders(),
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));

      return _processResponse(response);
    } catch (e) {
      throw AppExceptions.handleError(e);
    }
  }

  Future<dynamic> delete(String endpoint) async {
    try {
      final response = await _client
          .delete(
            Uri.parse(ApiEndpoints.baseUrl + endpoint),
            headers: _getHeaders(),
          )
          .timeout(const Duration(seconds: 30));

      return _processResponse(response);
    } catch (e) {
      throw AppExceptions.handleError(e);
    }
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  dynamic _processResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        if (response.body.isEmpty) {
          return null;
        }
        return jsonDecode(response.body);
      case 400:
        throw BadRequestException('Invalid request');
      case 401:
        throw UnauthorizedException('Unauthorized access');
      case 403:
        throw ForbiddenException('Access forbidden');
      case 404:
        throw NotFoundException('Resource not found');
      case 500:
        throw ServerException('Internal server error');
      default:
        throw FetchDataException(
            'Something went wrong (Status: ${response.statusCode})');
    }
  }

  void dispose() {
    _client.close();
  }
}
