import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:events_amo/widgets/comunity_event_card.dart';
import 'package:events_amo/providers/event_provider.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  @override
  void initState() {
    super.initState();
        WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<EventProvider>(context, listen: false);
      provider.searchEvents(widget.query);
    });
  }
  
   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Search Results"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (provider.searchResults?.content == null ||
              provider.searchResults!.content.isEmpty) {
            return Center(child: Text("No results found for '${widget.query}'"));
          } else {
            final events = provider.searchResults!.content;
            return ListView.builder(
              itemCount: events.length,
              itemBuilder: (context, index) {
                return CommunityEventCard(event: events[index]);
              },
            );
          }
        },
      ),
    );
  }
}
