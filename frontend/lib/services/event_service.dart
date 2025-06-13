import '../models/event.dart';
import '../models/page_response.dart';
import 'api_client.dart';

class EventService {
  final ApiClient _apiClient;

  EventService(this._apiClient);

  Future<PageResponse<Event>> getEvents({int page = 0, int size = 10}) async {
    final json = await _apiClient.get('/events?page=$page&size=$size', requiresAuth: false);
    return PageResponse.fromJson(json, (data) => Event.fromJson(data));
  }

  Future<Event> getEvent(int id) async {
    final json = await _apiClient.get('/eventGet/$id', requiresAuth: false);
    return Event.fromJson(json);
  }

  Future<PageResponse<Event>> getMainEvents({int page = 0, int size = 10}) async {
    final json = await _apiClient.get('/event/main?page=$page&size=$size', requiresAuth: false);
    return PageResponse.fromJson(json, (data) => Event.fromJson(data));
  }

  Future<PageResponse<Event>> getPromotedEvents({int page = 0, int size = 10}) async {
    final json = await _apiClient.get('/event/promoted?page=$page&size=$size', requiresAuth: false);
    return PageResponse.fromJson(json, (data) => Event.fromJson(data));
  }

  Future<PageResponse<Event>> getFilteredEvents(String city, String category, {int page = 0, int size = 10}) async {
    final json = await _apiClient.get('/event/filter?city=$city&category=$category&page=$page&size=$size', requiresAuth: false);
    return PageResponse.fromJson(json, (data) => Event.fromJson(data));
  }

  Future<PageResponse<Event>> searchEvents(String query, {int page = 0, int size = 10}) async {
    final json = await _apiClient.get('/event/search?search=$query&page=$page&size=$size', requiresAuth: false);
    return PageResponse.fromJson(json, (data) => Event.fromJson(data));
  }

  Future<Event> createEvent(Event event) async {
    final json = await _apiClient.post('/event', event.toJson());
    return Event.fromJson(json);
  }

  Future<Event> updateEvent(int id, Event event) async {
    final json = await _apiClient.put('/event/$id', event.toJson());
    return Event.fromJson(json);
  }

  Future<void> deleteEvent(int id) async {
    await _apiClient.delete('/event/$id');
  }

  Future<void> submitEventProposal(Event event) async {
    await _apiClient.post('/user/submit-event', event.toJson(), requiresAuth: false);
  }
}
