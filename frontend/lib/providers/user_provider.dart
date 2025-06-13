import 'package:events_amo/services/notification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/event.dart';
import '../models/user.dart';
import '../services/user_profile_service.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService;
  final UserProfileService _profileService;

  bool _isLoading = false;
  String? _error;
  List<Event> _savedEvents = [];
  List<Event> _attendingEvents = [];
  User? _currentUser;

  UserProvider(this._userService, this._profileService);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Event> get savedEvents => _savedEvents;
  List<Event> get attendingEvents => _attendingEvents;
  User? get currentUser => _currentUser;

  Future<void> fetchSavedEvents() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _savedEvents = await _userService.getSavedEvents();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchAttendingEvents() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _attendingEvents = await _userService.getAttendingEvents();

      // Schedule notifications for all attending events
      final notificationService = NotificationService();
      for (var event in _attendingEvents) {
        await notificationService.scheduleEventNotification(event);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> toggleSaveEvent(Event event, bool currentSavedStatus) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (currentSavedStatus) {
        await _userService.unsaveEvent(event.id);
        _savedEvents.removeWhere((e) => e.id == event.id);
      } else {
        await _userService.saveEvent(event.id);
        // Add the event to local list if it doesn't exist
        if (!_savedEvents.any((e) => e.id == event.id)) {
          _savedEvents.add(event);
        }
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleAttendEvent(
    Event event,
    bool currentAttendingStatus,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      final notificationService = NotificationService();

      if (currentAttendingStatus) {
        // User is unattending an event
        await _userService.unattendEvent(event.id);
        _attendingEvents.removeWhere((e) => e.id == event.id);

        // Cancel the notification for this event
        await notificationService.cancelEventNotification(event);
      } else {
        // User is attending an event
        await _userService.attendEvent(event.id);

        // Add the event to local list if it doesn't exist
        if (!_attendingEvents.any((e) => e.id == event.id)) {
          _attendingEvents.add(event);
        }

        // Schedule a notification for this event
        await notificationService.scheduleEventNotification(event);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  bool isEventSaved(Event event) {
    return _savedEvents.any((savedEvent) => savedEvent.id == event.id);
  }

  bool isEventAttending(Event event) {
    return _attendingEvents.any(
      (attendingEvent) => attendingEvent.id == event.id,
    );
  }

  Future<User?> loadCurrentUserIfNeeded() async {
    if (_currentUser != null) {
      return _currentUser;
    }

    try {
      _isLoading = true;
      notifyListeners();

      final user = await _userService.getCurrentUser();
      _currentUser = user;

      _isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> fetchCurrentUser() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await _userService.getCurrentUser();
      _currentUser = user;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> deleteCurrentUser() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _userService.deleteCurrentUser();

      // Reset local state
      clear();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Profile update methods
  Future<bool> updateUserProfile(String name, String lastName) async {
    if (_currentUser == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _profileService.updateUserProfile(name, lastName);
      _currentUser = result;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAvatar(int avatarId) async {
    if (_currentUser == null) return false;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _profileService.updateUserAvatar(avatarId);
      _currentUser = result;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _profileService.updateUserPassword(currentPassword, newPassword);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Future<bool> updateEmail(String currentPassword, String newEmail) async {
  //   try {
  //     _isLoading = true;
  //     _error = null;
  //     notifyListeners();

  //     await _profileService.updateUserEmail(currentPassword, newEmail);

  //     _isLoading = false;
  //     notifyListeners();
  //     return true;
  //   } catch (e) {
  //     _isLoading = false;
  //     _error = e.toString();
  //     print('Error updating email: $_error');
  //     notifyListeners();
  //     return false;
  //   }
  // }

  // Future<bool> verifyEmailChange(String verificationCode) async {
  //   try {
  //     _isLoading = true;
  //     _error = null;
  //     notifyListeners();

  //     await _profileService.verifyEmailChange(verificationCode);

  //     _isLoading = false;
  //     notifyListeners();
  //     return true;
  //   } catch (e) {
  //     _isLoading = false;
  //     _error = e.toString();
  //     print('Error verifying email change: $_error');
  //     notifyListeners();
  //     return false;
  //   }
  // }

  void clear() {
    // Cancel all event notifications
    NotificationService().cancelAllNotifications();

    _savedEvents.clear();
    _attendingEvents.clear();
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> submitEventProposal(Event event, List<XFile> images) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _userService.submitEventProposal(event, images);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchUserData() async {
    await fetchSavedEvents();
    await fetchAttendingEvents();
  }

  Future<bool> makeUserAdmin(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _userService.makeUserAdmin(email);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
