import 'package:events_amo/models/event.dart';
import 'package:events_amo/providers/event_provider.dart';
import 'package:events_amo/widgets/comunity_event_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearched = false;
  String _currentSearchQuery = '';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _currentSearchQuery = query;
    });

    try {
      await Provider.of<EventProvider>(context, listen: false).searchEvents(query);
      setState(() {
        _hasSearched = true;
        _isSearching = false;
      });
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching events: $e')),
      );
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _loadMoreResults() async {
    if (_currentSearchQuery.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      await Provider.of<EventProvider>(context, listen: false).loadMoreSearchResults(_currentSearchQuery);
    } catch (e) {
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more results: $e')),
      );
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onSubmitted: _performSearch,
                  decoration: InputDecoration(
                    hintText: "Search events",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            if (_hasSearched)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[400]),
                onPressed: () {
                  setState(() {
                    _hasSearched = false;
                    _currentSearchQuery = '';
                    _searchController.clear();
                  });
                },
              ),
          ],
        ),
      ),
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          if (!_hasSearched) {
            return _buildInitialSearchState();
          }

          if (_isSearching && provider.searchResults == null) {
            return Center(child: CircularProgressIndicator());
          }

          final searchResults = provider.searchResults;
          if (searchResults == null || searchResults.content.isEmpty) {
            return _buildNoResultsFound();
          }

          return _buildSearchResults(context, provider, searchResults.content);
        },
      ),
    );
  }

  Widget _buildInitialSearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 80, color: Colors.grey[600]),
          SizedBox(height: 20),
          Text(
            "Search for events by name, description, or location",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[600]),
          SizedBox(height: 20),
          Text(
            "No results found for '$_currentSearchQuery'",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 16),
          ),
          SizedBox(height: 10),
          Text(
            "Try a different search term",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, EventProvider provider, List<Event> events) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            provider.hasMoreSearchResults && !_isSearching) {
          _loadMoreResults();
          return true;
        }
        return false;
      },
      child: ListView.builder(
        padding: EdgeInsets.only(top: 16, bottom: 80), // Add bottom padding for nav bar
        itemCount: events.length + (provider.hasMoreSearchResults ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == events.length) {
            return _buildLoadMoreIndicator(context);
          }
          return CommunityEventCard(event: events[index]);
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.secondary,
      ),
    );
  }
}