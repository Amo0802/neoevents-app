import 'package:events_amo/models/user.dart';
import 'package:image_picker/image_picker.dart';

import '../models/event.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  Future<void> saveEvent(int eventId) async {
    await _apiClient.post('/user/save-event/$eventId', {});
  }

  Future<void> unsaveEvent(int eventId) async {
    await _apiClient.delete('/user/unsave-event/$eventId');
  }

  Future<List<Event>> getSavedEvents() async {
    final json = await _apiClient.get('/user/saved-events');
    return (json as List).map((item) => Event.fromJson(item)).toList();
  }

  Future<void> attendEvent(int eventId) async {
    await _apiClient.post('/user/attend-event/$eventId', {});
  }

  Future<void> unattendEvent(int eventId) async {
    await _apiClient.delete('/user/unattend-event/$eventId');
  }

  Future<List<Event>> getAttendingEvents() async {
    final json = await _apiClient.get('/user/attending-events');
    return (json as List).map((item) => Event.fromJson(item)).toList();
  }

  Future<User> getCurrentUser() async {
    final json = await _apiClient.get('/user/current');
    return User.fromJson(json);
  }

  Future<void> deleteCurrentUser() async {
    await _apiClient.delete('/user/current');
  }

  Future<void> deleteUser(int userId) async {
    await _apiClient.delete('/user/$userId');
  }

  Future<void> submitEventProposal(Event event, List<XFile> images) async {
    try {
      // Format event data according to EventRequestDTO structure
      final eventData = {
        'name': event.name,
        'description': event.description,
        'address': event.address,
        'startDateTime': event.startDateTime.toIso8601String(),
        'price': event.price.toString(),
        'categories': event.categories,
      };

      await _apiClient.postEventProposal(
        '/user/submit-event',
        eventData,
        images,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<User> makeUserAdmin(String email) async {
    final json = await _apiClient.put('/user/make-admin?email=$email', {});
    return User.fromJson(json);
  }
}
