import 'package:events_amo/models/event.dart';
import 'package:events_amo/pages/settings_page.dart';
import 'package:events_amo/providers/auth_provider.dart';
import 'package:events_amo/providers/user_provider.dart';
import 'package:events_amo/utils/width_constraint_wrapper.dart';
import 'package:events_amo/widgets/profile_event_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  bool _isRefreshing = false;
  
  @override
  void initState() {
    super.initState();
    // Fetch data when widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserData();
    });
  }
  
  Future<void> _fetchUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchSavedEvents();
    await userProvider.fetchAttendingEvents();
  }
  
  // Pull-to-refresh implementation
  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _fetchUserData();
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
        body: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            if (userProvider.isLoading && !_isRefreshing) {
              return const Center(child: CircularProgressIndicator());
            }

            final authProvider = Provider.of<AuthProvider>(context);
            final user = authProvider.currentUser;

            return RefreshIndicator(
              onRefresh: _handleRefresh,
              color: Theme.of(context).colorScheme.secondary,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(context),
                  _buildProfileHeader(
                    context,
                    user?.name ?? "Guest",
                    user?.lastName ?? "User",
                    user?.email ?? "guest@example.com",
                    user?.avatarId ?? 0,
                  ),
                  _buildTabSection(
                    context,
                    userProvider.attendingEvents.isEmpty
                        ? []
                        : userProvider.attendingEvents,
                    userProvider.savedEvents.isEmpty
                        ? []
                        : userProvider.savedEvents,
                  ),
                  // Add some extra space at the bottom
                  SliverToBoxAdapter(
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floating: true,
      title: Text(
        "My Profile",
        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.settings_outlined, color: Colors.white, size: 28),
          onPressed: () {
            // Navigate to settings
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WidthConstraintWrapper(child: SettingsPage())),
            );
          },
        ),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    String firstName,
    String lastName,
    String email,
    int avatarId,
  ) {
    // Generate avatar URL based on the avatarId
    String avatarUrl = _getAvatarUrl(firstName, lastName, avatarId);
    
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(avatarUrl),
            ),
            SizedBox(height: 16),
            Text(
              "$firstName $lastName",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              email,
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Edit profile
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondary.withValues(alpha: 0.2),
                foregroundColor: Theme.of(context).colorScheme.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 1.5,
                  ),
                ),
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: Text("Edit Profile"),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get the avatar URL based on avatarId
  String _getAvatarUrl(String firstName, String lastName, int avatarId) {
    // Array of avatar background colors
    final List<String> avatarBackgrounds = [
      '0D8ABC', // Blue
      'FF5733', // Orange/Red
      '28B463', // Green
      '7D3C98', // Purple
      'F1C40F', // Yellow
      '566573', // Grey
    ];
    
    // Ensure avatarId is within range
    final backgroundIndex = avatarId % avatarBackgrounds.length;
    final background = avatarBackgrounds[backgroundIndex];
    
    // Get initials for the avatar
    final String initials = ((firstName.isNotEmpty ? firstName[0] : '') + 
                            (lastName.isNotEmpty ? lastName[0] : '')).toUpperCase();
    
    // Return the URL for the UI Avatars service
    return 'https://ui-avatars.com/api/?background=$background&color=fff&name=$initials&size=256';
  }

  Widget _buildTabSection(
    BuildContext context,
    List<Event> attendingEvents,
    List<Event> savedEvents,
  ) {
    return SliverToBoxAdapter(
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            SizedBox(height: 20),
            TabBar(
              tabs: [
                Tab(text: "Upcoming"),
                Tab(text: "Saved"),
              ],
              labelColor: Theme.of(context).colorScheme.secondary,
              unselectedLabelColor: Colors.grey[500],
              indicatorColor: Theme.of(context).colorScheme.secondary,
              indicatorSize: TabBarIndicatorSize.label,
            ),
            Container(
              height: 400,
              padding: EdgeInsets.only(top: 20),
              child: TabBarView(
                children: [
                  _buildUpcomingEvents(context, attendingEvents),
                  _buildSavedEvents(context, savedEvents),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingEvents(
    BuildContext context,
    List<Event> attendingEvents,
  ) {
    if (attendingEvents.isEmpty) {
      return Center(
        child: Text(
          "You have no upcoming events",
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: attendingEvents.length,
      itemBuilder: (context, index) {
        return ProfileEventCard(event: attendingEvents[index]);
      },
    );
  }

  Widget _buildSavedEvents(BuildContext context, List<Event> savedEvents) {
    if (savedEvents.isEmpty) {
      return Center(
        child: Text(
          "You have no saved events",
          style: TextStyle(color: Colors.grey[500], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: savedEvents.length,
      itemBuilder: (context, index) {
        return ProfileEventCard(event: savedEvents[index]);
      },
    );
  }
}