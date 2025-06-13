import 'package:events_amo/pages/admin/admin_create_event_menu.dart';
import 'package:events_amo/pages/community_events_page.dart';
import 'package:events_amo/pages/home_page.dart';
import 'package:events_amo/pages/login_page.dart';
import 'package:events_amo/pages/profile_page.dart';
import 'package:events_amo/pages/search_page.dart';
import 'package:events_amo/pages/create_events.dart';
import 'package:events_amo/providers/auth_provider.dart';
import 'package:events_amo/providers/event_provider.dart';
import 'package:events_amo/providers/user_provider.dart';
import 'package:events_amo/utils/width_constraint_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  final int initialTabIndex;

  const MainPage({super.key, this.initialTabIndex = 0});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  late int _currentIndex;
  bool _isCreateMenuOpen = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    _pages = [HomePage(), CommunityEventsPage(), ProfilePage(), SearchPage()];
    
    // Register this object as an observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove the observer when this widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // This method is called when the app lifecycle state changes
    if (state == AppLifecycleState.resumed) {
      // App has come back to the foreground
      _refreshData();
    }
  }

  void _refreshData() {
    // Don't refresh if the context is no longer valid
    if (!mounted) return;
    
    try {
      // Refresh event data
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      eventProvider.fetchMainEvents();
      eventProvider.fetchPromotedEvents();
      
      // Refresh user data if logged in
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.status == AuthStatus.authenticated) {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.fetchSavedEvents();
        userProvider.fetchAttendingEvents();
      }
    } catch (e) {
      ('Error refreshing data: $e');
      // Don't show error to user - this is a background refresh
    }
  }

  void _onTabSelected(int index) {
    final authProvider = context.read<AuthProvider>();

    if (index == 2) {
      if (authProvider.status == AuthStatus.authenticated) {
        setState(() {
          _currentIndex = 2;
        });
      } else {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const WidthConstraintWrapper(child: LoginPage())));
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _handleCreateButtonPressed() {
    final authProvider = context.read<AuthProvider>();

    // If user is not logged in, redirect to login page
    if (authProvider.status != AuthStatus.authenticated) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const WidthConstraintWrapper(child: LoginPage())));
      return;
    }

    // Debug - check admin status
    (
      "User admin status check: ${authProvider.currentUser?.email}, isAdmin: ${authProvider.isAdmin}",
    );

    // If user is admin, show admin menu options
    if (authProvider.isAdmin) {
      ("Opening admin menu options");
      setState(() {
        _isCreateMenuOpen = true;
      });
      return;
    }

    // If regular user, go directly to create event page
    ("Opening regular user create event page");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WidthConstraintWrapper(child: CreateEventPage())),
    );
  }

  void _toggleCreateMenu() {
    setState(() {
      _isCreateMenuOpen = !_isCreateMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color iconColor(int index) {
      return _currentIndex == index
          ? theme.colorScheme.secondary
          : Colors.white60;
    }

    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.isAdmin;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          if (_isCreateMenuOpen)
            GestureDetector(
              onTap: () {
                if (isAdmin) {
                  _toggleCreateMenu(); // Open admin menu
                } else {
                  // First close the overlay
                  Navigator.of(context).pop();

                  // Then navigate to CreateEventPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WidthConstraintWrapper(child: CreateEventPage())),
                  );
                }
              },
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child:
                      isAdmin
                          ? AdminCreateEventMenu(onClose: _toggleCreateMenu)
                          : const SizedBox(), // Nothing shown if not admin
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF171C30),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.home_outlined, size: 28, color: iconColor(0)),
                onPressed: () => _onTabSelected(0),
              ),
              IconButton(
                icon: Icon(
                  Icons.explore_outlined,
                  size: 28,
                  color: iconColor(1),
                ),
                onPressed: () => _onTabSelected(1),
              ),
              const SizedBox(width: 60),
              IconButton(
                icon: Icon(
                  Icons.search_outlined,
                  size: 28,
                  color: iconColor(3),
                ),
                onPressed: () => _onTabSelected(3),
              ),
              IconButton(
                icon: Icon(Icons.person_outline, size: 28, color: iconColor(2)),
                onPressed: () => _onTabSelected(2),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.colorScheme.tertiary,
        onPressed: _handleCreateButtonPressed,
        child: Icon(_isCreateMenuOpen ? Icons.close : Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}