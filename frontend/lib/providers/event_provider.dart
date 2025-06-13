// import 'package:events_amo/providers/user_provider.dart';
// import 'package:events_amo/services/navigation_service.dart';
import 'package:flutter/foundation.dart';
// import 'package:provider/provider.dart';
import '../models/event.dart';
import '../models/page_response.dart';
import '../services/event_service.dart';

class EventProvider with ChangeNotifier {
  final EventService _eventService;

  bool _isLoading = false;
  String? _error;
  PageResponse<Event>? _events;
  PageResponse<Event>? _mainEvents;
  PageResponse<Event>? _promotedEvents;
  PageResponse<Event>? _filteredEvents;
  PageResponse<Event>? _searchResults;
  Event? _selectedEvent;

  EventProvider(this._eventService) {
    // Initialize data loading when provider is created
    fetchMainEvents();
    fetchPromotedEvents();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  PageResponse<Event>? get events => _events;
  PageResponse<Event>? get mainEvents => _mainEvents;
  PageResponse<Event>? get promotedEvents => _promotedEvents;
  PageResponse<Event>? get filteredEvents => _filteredEvents;
  PageResponse<Event>? get searchResults => _searchResults;
  Event? get selectedEvent => _selectedEvent;

  Future<void> fetchEvents({int page = 0, int size = 10}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _events = await _eventService.getEvents(page: page, size: size);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchMainEvents({int page = 0, int size = 10}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _mainEvents = await _eventService.getMainEvents(page: page, size: size);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchPromotedEvents({int page = 0, int size = 10}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _promotedEvents = await _eventService.getPromotedEvents(
        page: page,
        size: size,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchFilteredEvents(
    String city,
    String category, {
    int page = 0,
    int size = 10,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _filteredEvents = await _eventService.getFilteredEvents(
        city,
        category,
        page: page,
        size: size,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> searchEvents(String query, {int page = 0, int size = 10}) async {
    if (query.isEmpty) {
      _searchResults = null;
      notifyListeners();
      return;
    }

    try {
      _isLoading = true;
      _error = null;
      _hasMoreSearchResults =
          true; // Reset this flag when starting a new search
      notifyListeners();

      _searchResults = await _eventService.searchEvents(
        query,
        page: page,
        size: size,
      );

      // Set the flag based on whether there are more pages
      _hasMoreSearchResults = !_searchResults!.last;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchEventById(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _selectedEvent = await _eventService.getEvent(id);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> createEvent(Event event) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _eventService.createEvent(event);

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

  Future<bool> updateEvent(int id, Event event) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _eventService.updateEvent(id, event);

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

  Future<bool> deleteEvent(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _eventService.deleteEvent(id);

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

  Future<bool> submitEventProposal(Event event) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _eventService.submitEventProposal(event);

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

  // Helper method to clear errors
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset method for testing
  void reset() {
    _isLoading = false;
    _error = null;
    _events = null;
    _mainEvents = null;
    _promotedEvents = null;
    _filteredEvents = null;
    _searchResults = null;
    _selectedEvent = null;
    notifyListeners();
  }

  bool _isLoadingMore = false;
  bool _hasMoreEvents = true;
  bool _hasMoreMainEvents = true;
  bool _hasMorePromotedEvents = true;
  bool _hasMoreFilteredEvents = true;
  bool _hasMoreSearchResults = true;

  // Add these getters
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMoreEvents => _hasMoreEvents;
  bool get hasMoreMainEvents => _hasMoreMainEvents;
  bool get hasMorePromotedEvents => _hasMorePromotedEvents;
  bool get hasMoreFilteredEvents => _hasMoreFilteredEvents;
  bool get hasMoreSearchResults => _hasMoreSearchResults;

  // Add methods to load more events for each type
  Future<void> loadMoreEvents() async {
    if (_isLoadingMore || !_hasMoreEvents || _events == null) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final nextPage = _events!.pageNumber + 1;
      if (nextPage >= _events!.totalPages) {
        _hasMoreEvents = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      final moreEvents = await _eventService.getEvents(
        page: nextPage,
        size: _events!.pageSize,
      );

      // Append the new events
      final updatedContent = List<Event>.from(_events!.content)
        ..addAll(moreEvents.content);

      _events = PageResponse(
        content: updatedContent,
        pageNumber: moreEvents.pageNumber,
        pageSize: moreEvents.pageSize,
        totalElements: moreEvents.totalElements,
        totalPages: moreEvents.totalPages,
        currentPageNumberOfElements:
            _events!.currentPageNumberOfElements +
            moreEvents.currentPageNumberOfElements,
        last: moreEvents.last,
      );

      _hasMoreEvents = !moreEvents.last;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Similar methods for other event types (main, promoted, filtered, search)
  Future<void> loadMoreMainEvents() async {
    if (_isLoadingMore || !_hasMoreMainEvents || _mainEvents == null) return;

    try {
      _isLoadingMore = true;
      notifyListeners();

      final nextPage = _mainEvents!.pageNumber + 1;
      if (nextPage >= _mainEvents!.totalPages) {
        _hasMoreMainEvents = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      final moreEvents = await _eventService.getMainEvents(
        page: nextPage,
        size: _mainEvents!.pageSize,
      );

      // Append the new events
      final updatedContent = List<Event>.from(_mainEvents!.content)
        ..addAll(moreEvents.content);

      _mainEvents = PageResponse(
        content: updatedContent,
        pageNumber: moreEvents.pageNumber,
        pageSize: moreEvents.pageSize,
        totalElements: moreEvents.totalElements,
        totalPages: moreEvents.totalPages,
        currentPageNumberOfElements:
            _mainEvents!.currentPageNumberOfElements +
            moreEvents.currentPageNumberOfElements,
        last: moreEvents.last,
      );

      _hasMoreMainEvents = !moreEvents.last;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMoreFilteredEvents(
    String city,
    String category, {
    int? page,
  }) async {
    if (_isLoadingMore || !_hasMoreFilteredEvents || _filteredEvents == null) {
      return;
    }

    try {
      _isLoadingMore = true;
      notifyListeners();

      final nextPage = page ?? _filteredEvents!.pageNumber + 1;
      if (nextPage >= _filteredEvents!.totalPages) {
        _hasMoreFilteredEvents = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      final moreEvents = await _eventService.getFilteredEvents(
        city,
        category,
        page: nextPage,
        size: _filteredEvents!.pageSize,
      );

      // Append the new events
      final updatedContent = List<Event>.from(_filteredEvents!.content)
        ..addAll(moreEvents.content);

      _filteredEvents = PageResponse(
        content: updatedContent,
        pageNumber: moreEvents.pageNumber,
        pageSize: moreEvents.pageSize,
        totalElements: moreEvents.totalElements,
        totalPages: moreEvents.totalPages,
        currentPageNumberOfElements:
            _filteredEvents!.currentPageNumberOfElements +
            moreEvents.currentPageNumberOfElements,
        last: moreEvents.last,
      );

      _hasMoreFilteredEvents = !moreEvents.last;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMorePromotedEvents() async {
    if (_isLoadingMore || !_hasMorePromotedEvents || _promotedEvents == null) {
      return;
    }

    try {
      _isLoadingMore = true;
      notifyListeners();

      final nextPage = _promotedEvents!.pageNumber + 1;
      if (nextPage >= _promotedEvents!.totalPages) {
        _hasMorePromotedEvents = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      final moreEvents = await _eventService.getPromotedEvents(
        page: nextPage,
        size: _promotedEvents!.pageSize,
      );

      // Append the new events
      final updatedContent = List<Event>.from(_promotedEvents!.content)
        ..addAll(moreEvents.content);

      _promotedEvents = PageResponse(
        content: updatedContent,
        pageNumber: moreEvents.pageNumber,
        pageSize: moreEvents.pageSize,
        totalElements: moreEvents.totalElements,
        totalPages: moreEvents.totalPages,
        currentPageNumberOfElements:
            _promotedEvents!.currentPageNumberOfElements +
            moreEvents.currentPageNumberOfElements,
        last: moreEvents.last,
      );

      _hasMorePromotedEvents = !moreEvents.last;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadMoreSearchResults(String query) async {
    if (_isLoadingMore || !_hasMoreSearchResults || _searchResults == null) {
      return;
    }

    try {
      _isLoadingMore = true;
      notifyListeners();

      final nextPage = _searchResults!.pageNumber + 1;
      if (nextPage >= _searchResults!.totalPages) {
        _hasMoreSearchResults = false;
        _isLoadingMore = false;
        notifyListeners();
        return;
      }

      final moreResults = await _eventService.searchEvents(
        query,
        page: nextPage,
        size: _searchResults!.pageSize,
      );

      // Append the new events
      final updatedContent = List<Event>.from(_searchResults!.content)
        ..addAll(moreResults.content);

      _searchResults = PageResponse(
        content: updatedContent,
        pageNumber: moreResults.pageNumber,
        pageSize: moreResults.pageSize,
        totalElements: moreResults.totalElements,
        totalPages: moreResults.totalPages,
        currentPageNumberOfElements:
            _searchResults!.currentPageNumberOfElements +
            moreResults.currentPageNumberOfElements,
        last: moreResults.last,
      );

      _hasMoreSearchResults = !moreResults.last;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoadingMore = false;
      _error = e.toString();
      notifyListeners();
    }
  }
}
