import 'dart:io';
import 'package:dio/dio.dart';
import '../config/api_config.dart';
import '../services/token_storage_service.dart';
import '../utils/dependency_injection.dart';

/// Base API service class that provides common functionality for all API services
class BaseApiService {
  late final Dio dio;
  late final TokenStorageService _tokenStorage;

  BaseApiService() {
    dio = locator<Dio>();
    _tokenStorage = locator<TokenStorageService>();
  }

  /// Get default headers with authorization token
  Future<Map<String, dynamic>> _getHeaders({
    bool includeAuth = true,
    Map<String, dynamic>? additionalHeaders,
  }) async {
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (includeAuth) {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Handle Dio errors and return standardized error response
  Map<String, dynamic> _handleError(DioException e) {
    late int status;

    if (e.error is SocketException || e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.sendTimeout || e.type == DioExceptionType.receiveTimeout) {
      status = -3; // Connection error
    } else if (e.response?.statusCode == 401) {
      status = -1; // Unauthorized - session expired
    } else {
      status = -2; // General error
    }

    final errorResponse = <String, dynamic>{
      'status': status,
      'success': false,
      'message': _getErrorMessage(status, e),
    };

    if (e.response?.data != null && e.response!.data is Map) {
      final responseData = e.response!.data as Map<String, dynamic>;
      if (responseData.containsKey('errors')) {
        errorResponse['errors'] = responseData['errors'];
      }
      if (responseData.containsKey('message') && responseData['message'] != null) {
        errorResponse['message'] = responseData['message'];
      }
    }

    return errorResponse;
  }

  /// Get user-friendly error message based on status code
  String _getErrorMessage(int status, DioException e) {
    switch (status) {
      case -3:
        return 'Connection error. Please check your internet connection.';
      case -2:
        return e.response?.data?['message'] ?? 'An error occurred';
      case -1:
        return 'Session expired. Please log in again.';
      default:
        return 'An unexpected error occurred';
    }
  }

  /// Make a GET request
  Future<Map<String, dynamic>> getRequest(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    bool includeAuth = true,
    String? baseUrl,
  }) async {
    try {
      dio.options.headers = await _getHeaders(includeAuth: includeAuth);

      final url = baseUrl ?? '${ApiConfig.baseUrl}$endpoint';
      final response = await dio.get(url, queryParameters: queryParameters);

      return _processResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return {
        'status': -2,
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Make a POST request
  Future<Map<String, dynamic>> postRequest(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool includeAuth = true,
    String? baseUrl,
  }) async {
    try {
      dio.options.headers = await _getHeaders(includeAuth: includeAuth);

      final url = baseUrl ?? '${ApiConfig.baseUrl}$endpoint';
      final response = await dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
      );

      return _processResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return {
        'status': -2,
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Make a PUT request
  Future<Map<String, dynamic>> putRequest(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool includeAuth = true,
    String? baseUrl,
  }) async {
    try {
      dio.options.headers = await _getHeaders(includeAuth: includeAuth);

      final url = baseUrl ?? '${ApiConfig.baseUrl}$endpoint';
      final response = await dio.put(
        url,
        data: data,
        queryParameters: queryParameters,
      );

      return _processResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return {
        'status': -2,
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Make a DELETE request
  Future<Map<String, dynamic>> deleteRequest(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    bool includeAuth = true,
    String? baseUrl,
  }) async {
    try {
      dio.options.headers = await _getHeaders(includeAuth: includeAuth);

      final url = baseUrl ?? '${ApiConfig.baseUrl}$endpoint';
      final response = await dio.delete(
        url,
        data: data,
        queryParameters: queryParameters,
      );

      return _processResponse(response);
    } on DioException catch (e) {
      return _handleError(e);
    } catch (e) {
      return {
        'status': -2,
        'success': false,
        'message': 'An unexpected error occurred',
      };
    }
  }

  /// Process the response from the server
  Map<String, dynamic> _processResponse(Response response) {
    // Check if response is successful
    if (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300) {
      final data = response.data;

      // If data is already a map, return it
      if (data is Map<String, dynamic>) {
        return data;
      }

      // If data is a string, try to decode it
      if (data is String) {
        return {
          'success': true,
          'data': data,
        };
      }

      // Return raw data
      return {
        'success': true,
        'data': data,
      };
    }

    // Non-success status code
    return {
      'success': false,
      'status': response.statusCode,
      'message': 'Request failed with status ${response.statusCode}',
    };
  }
}
