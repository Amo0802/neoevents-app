import '../models/auth_request.dart';
import '../models/auth_response.dart';
import '../models/register_request.dart';
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient;

  AuthService(this._apiClient);

  Future<AuthResponse> register(RegisterRequest request) async {
    final json = await _apiClient.post(
      '/auth/register',
      request.toJson(),
      requiresAuth: false,
    );
    final authResponse = AuthResponse.fromJson(json);
    await _apiClient.saveAuthToken(authResponse.token);
    return authResponse;
  }

  Future<AuthResponse> login(AuthRequest request) async {
    final json = await _apiClient.post(
      '/auth/authenticate',
      request.toJson(),
      requiresAuth: false,
    );
    final authResponse = AuthResponse.fromJson(json);
    await _apiClient.saveAuthToken(authResponse.token);
    return authResponse;
  }

  Future<void> logout() async {
    await _apiClient.clearAuthToken();
  }

  Future<bool> isAuthenticated() async {
    final token = await _apiClient.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  Future<User> getCurrentUser() async {
    final json = await _apiClient.get('/user/current');
    return User.fromJson(json);
  }

}
