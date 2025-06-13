import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Add this import
import 'package:image_picker/image_picker.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  late final Dio _dio;
  final String _baseUrl;
  
  // Use secure storage instead of SharedPreferences
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String _tokenKey = 'auth_token';

ApiClient._internal() : _baseUrl = const String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8080') {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      contentType: 'application/json',
      responseType: ResponseType.json,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));
    
    // Add logging interceptor for debugging
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<void> clearAuthToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  Future<Options> _getOptions({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = await getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return Options(headers: headers);
  }

  Future<dynamic> get(String endpoint, {bool requiresAuth = true}) async {
    try {
      final options = await _getOptions(requiresAuth: requiresAuth);
      final response = await _dio.get(endpoint, options: options);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<dynamic> post(String endpoint, dynamic body, {bool requiresAuth = true}) async {
    try {
      final options = await _getOptions(requiresAuth: requiresAuth);
      final response = await _dio.post(endpoint, data: body, options: options);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<dynamic> put(String endpoint, dynamic body, {bool requiresAuth = true}) async {
    try {
      final options = await _getOptions(requiresAuth: requiresAuth);
      final response = await _dio.put(endpoint, data: body, options: options);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<dynamic> delete(String endpoint, {bool requiresAuth = true}) async {
    try {
      final options = await _getOptions(requiresAuth: requiresAuth);
      final response = await _dio.delete(endpoint, options: options);
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  Future<Response> postFormData(String endpoint, FormData data, {bool requiresAuth = true}) async {
    try {
      final options = await _getOptions(requiresAuth: requiresAuth);
      final response = await _dio.post(endpoint, data: data, options: options);
      return response;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  void _handleDioError(DioException error) {
    final status = error.response?.statusCode;
    
    if (status == 401) {
      throw Exception('Unauthorized: Your session may have expired. Please log in again.');
    } else if (status == 403) {
      throw Exception('Forbidden: You don\'t have permission to access this resource.');
    } else if (status == 404) {
      throw Exception('Not found: The requested resource could not be found.');
    } else if (status == 500) {
      throw Exception('Server error: Something went wrong on the server.');
    } else {
      throw Exception('API Error: ${error.message}');
    }
  }

  Future<dynamic> postEventProposal(String endpoint, Map<String, dynamic> eventData, List<XFile> images) async {
    try {
      final token = await getAuthToken();
      
      // Create form data
      FormData formData = FormData();
      
      // Convert event data to a JSON string
      String eventJson = jsonEncode(eventData);
      
      // Add as a "file" with application/json content type
      formData.files.add(
        MapEntry(
          'event',
          MultipartFile.fromString(
            eventJson,
            contentType: MediaType.parse('application/json'),
          ),
        ),
      );
      
      // Add image files
      for (var image in images) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              image.path,
              filename: image.name,
            ),
          ),
        );
      }
      
      // Set headers
      final headers = {
        'Accept': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(headers: headers),
      );
      
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }
}