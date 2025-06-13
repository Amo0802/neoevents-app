import 'package:events_amo/providers/user_provider.dart';
import 'package:events_amo/services/navigation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/auth_request.dart';
import '../models/register_request.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
}

class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  
  AuthStatus _status = AuthStatus.initial;
  User? _currentUser;
  String? _error;
  
  AuthProvider(this._authService) {
    _checkAuthStatus();
  }
  
  AuthStatus get status => _status;
  User? get currentUser => _currentUser;
  String? get error => _error;
  
  // Make sure the isAdmin getter returns the value from the User object
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  
  Future<void> _checkAuthStatus() async {
    try {
      final isAuthenticated = await _authService.isAuthenticated();
      
      if (isAuthenticated) {
        _currentUser = await _authService.getCurrentUser();
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.toString();
    }
    
    notifyListeners();
  }
  
  Future<bool> register(String name, String lastName, String email, String password) async {
    try {
      _error = null;
      _status = AuthStatus.initial;
      notifyListeners();
      
      final request = RegisterRequest(
        name: name,
        lastName: lastName,
        email: email,
        password: password,
      );
      
      await _authService.register(request);
      _currentUser = await _authService.getCurrentUser();
      _status = AuthStatus.authenticated;
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> login(String email, String password) async {
    try {
      _error = null;
      _status = AuthStatus.initial;
      notifyListeners();
      
      final request = AuthRequest(
        email: email,
        password: password,
      );
      
      await _authService.login(request);
      _currentUser = await _authService.getCurrentUser();
      _status = AuthStatus.authenticated;
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }
  
Future<void> logout() async {
  try {
    // Clear user data
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.clear();
      } catch (e) {
      _error = e.toString();
      _status = AuthStatus.unauthenticated;
      }
    }
    
    await _authService.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
  } catch (e) {
    _error = e.toString();
    _status = AuthStatus.unauthenticated;
  }
  notifyListeners();
}
  
  Future<void> refreshUser() async {
    try {
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Add a method to clear errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}