import 'package:events_amo/models/event.dart';
import 'package:events_amo/pages/admin/make_admin.dart';
import 'package:events_amo/providers/auth_provider.dart';
import 'package:events_amo/providers/event_provider.dart';
import 'package:events_amo/widgets/featured_event_card.dart';
import 'package:events_amo/widgets/standard_event_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  bool _isRefreshing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
    
    // Fetch data when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more data when we're 200 pixels from the bottom
      final provider = Provider.of<EventProvider>(context, listen: false);
      if (!provider.isLoadingMore && provider.hasMoreMainEvents) {
        provider.loadMoreMainEvents();
      }
    }
  }

  Future<void> _fetchData() async {
    final provider = Provider.of<EventProvider>(context, listen: false);
    await provider.fetchPromotedEvents();
    await provider.fetchMainEvents();
  }

  // Pull-to-refresh implementation
  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh data. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
    return;
  }

  void _showMakeAdminDialog() {
    showDialog(
      context: context,
      builder: (_) => MakeAdminDialog(),
    ).then((success) {
      if (mounted && success == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User has been made admin successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;
    
    return SafeArea(
      child: Scaffold(
        body: Consumer<EventProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && !_isRefreshing) {
              return const Center(child: CircularProgressIndicator());
            }

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: Theme.of(context).colorScheme.secondary,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildAppBar(context, isAdmin),
                  _buildPromotedEvents(
                    context,
                    provider.promotedEvents?.content ?? [],
                  ),
                  _buildUpcomingEvents(
                    context,
                    provider.mainEvents?.content ?? [],
                  ),
                  // Add loading indicator at the bottom if more items are available
                  if (provider.mainEvents != null && provider.hasMoreMainEvents)
                    SliverToBoxAdapter(
                      child: provider.isLoadingMore
                          ? Container(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            )
                          : SizedBox(height: 60), // Spacer
                    ),
                  // Add extra space at bottom
                  SliverToBoxAdapter(
                    child: SizedBox(height: 20),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isAdmin) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floating: true,
      title: Row(
        children: [
          Text(
            "Neo",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            "Events",
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ],
      ),
      actions: [
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: Icon(
                Icons.admin_panel_settings,
                color: Theme.of(context).colorScheme.tertiary,
                size: 28,
              ),
              onPressed: _showMakeAdminDialog,
              tooltip: "Make User Admin",
            ),
          ),
      ],
    );
  }

  Widget _buildPromotedEvents(
    BuildContext context,
    List<Event> promotedEvents,
  ) {
    if (promotedEvents.isEmpty) {
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  "Promoted Events",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
          CarouselSlider.builder(
            itemCount: promotedEvents.length,
            itemBuilder: (context, index, _) {
              final event = promotedEvents[index];
              return FeaturedEventCard(event: event);
            },
            options: CarouselOptions(
              height: 320,
              enlargeCenterPage: true,
              autoPlay: true,
              viewportFraction: 0.85,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents(BuildContext context, List<Event> events) {
    if (events.isEmpty) return SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Icon(
                  Icons.event_available,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Upcoming Official Events",
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }
        
        final eventIndex = index - 1;
        if (eventIndex >= events.length) {
          return null;
        }
        
        final event = events[eventIndex];
        return StandardEventCard(event: event);
      }, childCount: events.length + 1), // +1 for the header
    );
  }
}