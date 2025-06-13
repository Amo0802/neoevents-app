import 'package:events_amo/models/user.dart';
import 'api_client.dart';

class UserProfileService {
  final ApiClient _apiClient;

  UserProfileService(this._apiClient);

  /// Update user profile information
Future<User> updateUserProfile(String newName, String newLastName) async {
  try {
    // Update to use /user/profile endpoint instead of /user/{id}
    final json = await _apiClient.put('/user/profile', {
      'newName': newName,
      'newLastName': newLastName
      });
    return User.fromJson(json);
  } catch (e) {
    rethrow;
  }
}

  /// Update user's avatar
  Future<User> updateUserAvatar(int avatarId) async {
    try {
      // This endpoint would need to be created in the backend
      final json = await _apiClient.put('/user/avatar', {
        'avatarId': avatarId
        });
      return User.fromJson(json);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user's password
  Future<void> updateUserPassword(String currentPassword, String newPassword) async {
    try {
      // This endpoint would need to be created in the backend
      await _apiClient.put('/user/password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword
      });
    } catch (e) {
      rethrow;
    }
  }
}

//   /// Update user's email
//   Future<void> updateUserEmail(String currentPassword, String newEmail) async {
//     try {
//       // This endpoint would need to be created in the backend
//       await _apiClient.put('/user/email', {
//         'currentPassword': currentPassword,
//         'newEmail': newEmail
//       });
//     } catch (e) {
//       print('Error updating user email: $e');
//       rethrow;
//     }
//   }

//   /// Verify email change with verification code
//   Future<void> verifyEmailChange(String verificationCode) async {
//     try {
//       // This endpoint would need to be created in the backend
//       await _apiClient.put('/user/verify-email', {
//         'verificationCode': verificationCode
//       });
//     } catch (e) {
//       print('Error verifying email change: $e');
//       rethrow;
//     }
//   }
// }