import 'package:events_amo/providers/event_provider.dart';
import 'package:events_amo/widgets/comunity_event_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommunityEventsPage extends StatefulWidget {
  const CommunityEventsPage({super.key});

  @override
  CommunityEventsPageState createState() => CommunityEventsPageState();
}

class CommunityEventsPageState extends State<CommunityEventsPage> {
  String selectedCity = 'ALL';
  String selectedCategory = 'ALL';
  bool _isRefreshing = false;
  final ScrollController _scrollController = ScrollController();

  final List<String> cities = ['ALL', 'SPAIN', 'FRANCE', 'GERMANY', 'ITALY'];

  final List<String> categories = [
    'ALL',
    'SPORTS',
    'MUSIC',
    'ART',
    'FOOD',
    'TECHNOLOGY',
  ];

  @override
  void initState() {
    super.initState();

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);

    // Fetch data when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchFilteredEvents();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more data when we're 200 pixels from the bottom
      final provider = Provider.of<EventProvider>(context, listen: false);
      if (!provider.isLoadingMore && provider.hasMoreFilteredEvents) {
        provider.loadMoreFilteredEvents(selectedCity, selectedCategory);
      }
    }
  }

  Future<void> _fetchFilteredEvents() async {
    final provider = Provider.of<EventProvider>(context, listen: false);
    await provider.fetchFilteredEvents(selectedCity, selectedCategory);
  }

  // Pull-to-refresh implementation
  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _fetchFilteredEvents();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Consumer<EventProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: Theme.of(context).colorScheme.secondary,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildCityDropdown(context),
                  _buildCategoryFilter(context, provider),
                  if (provider.isLoading && !_isRefreshing)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (provider.filteredEvents == null ||
                      provider.filteredEvents!.content.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text("No events found."),
                        ),
                      ),
                    )
                  else
                    _buildEventsList(context, provider),
                  // Add loading indicator at the bottom if more items are available
                  if (provider.filteredEvents != null &&
                      provider.hasMoreFilteredEvents)
                    SliverToBoxAdapter(
                      child:
                          provider.isLoadingMore
                              ? Container(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                alignment: Alignment.center,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              )
                              : SizedBox(height: 60), // Spacer
                    ),
                  // Add extra space at bottom
                  SliverToBoxAdapter(child: SizedBox(height: 20)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCityDropdown(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: DropdownButtonFormField<String>(
          value: selectedCity,
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ),
          dropdownColor: Theme.of(context).scaffoldBackgroundColor,
          icon: Icon(
            Icons.location_on_outlined,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() => selectedCity = newValue);
              Provider.of<EventProvider>(
                context,
                listen: false,
              ).fetchFilteredEvents(selectedCity, selectedCategory);
            }
          },
          items:
              cities.map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter(BuildContext context, EventProvider provider) {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(vertical: 10),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category == selectedCategory;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 8.0, 0),
                  child: Text(
                    overflow: TextOverflow.visible,
                    category.toUpperCase(),
                    style: TextStyle(
                      color:
                          isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                backgroundColor:
                    isSelected
                        ? Theme.of(
                          context,
                        ).colorScheme.tertiary.withValues(alpha: 0.3)
                        : Theme.of(context).scaffoldBackgroundColor,
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() => selectedCategory = category);
                  provider.fetchFilteredEvents(selectedCity, category);
                },
                selectedColor: Theme.of(
                  context,
                ).colorScheme.tertiary.withValues(alpha: 0.3),
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(
                              context,
                            ).colorScheme.secondary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, EventProvider provider) {
    final events = provider.filteredEvents!.content;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index >= events.length) {
          return null;
        }
        return CommunityEventCard(event: events[index]);
      }, childCount: events.length),
    );
  }
}
