import 'package:events_amo/models/event.dart';
import 'package:events_amo/pages/login_page.dart';
import 'package:events_amo/providers/auth_provider.dart';
import 'package:events_amo/providers/user_provider.dart';
import 'package:events_amo/utils/notification_permission_handler.dart';
import 'package:events_amo/utils/width_constraint_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class EventDetailPage extends StatefulWidget {
  final Event event;

  const EventDetailPage({super.key, required this.event});

  @override
  EventDetailPageState createState() => EventDetailPageState();
}

class EventDetailPageState extends State<EventDetailPage> {
  bool isExpanded = false;
  bool _isProcessing = false;

  void _toggleSave(bool isSaved) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is logged in
    if (authProvider.status != AuthStatus.authenticated) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) =>const WidthConstraintWrapper(child: LoginPage())));
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    userProvider
        .toggleSaveEvent(widget.event, isSaved)
        .then((_) {
          // Force UI update
          setState(() {});
        })
        .whenComplete(() {
          setState(() {
            _isProcessing = false;
          });
        });
  }

  void _toggleAttend(bool isAttending) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is logged in
    if (authProvider.status != AuthStatus.authenticated) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const WidthConstraintWrapper(child: LoginPage())));
      return;
    }

    if (_isProcessing) return;

    // If we're going to attend (not already attending), ask for notification permission
    if (!isAttending) {
      final hasPermission =
          await NotificationPermissionHandler.requestPermission(context);
      if (mounted && hasPermission) {
        // Inform user about the notification
        NotificationPermissionHandler.showNotificationConfirmation(
          context,
          widget.event,
        );
      }
    }

    setState(() {
      _isProcessing = true;
    });

    userProvider
        .toggleAttendEvent(widget.event, isAttending)
        .then((_) {
          // Force UI update
          setState(() {});
        })
        .whenComplete(() {
          setState(() {
            _isProcessing = false;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    // Get current status from UserProvider
    final userProvider = Provider.of<UserProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final bool isLoggedIn = authProvider.status == AuthStatus.authenticated;
    final bool isSaved = isLoggedIn && userProvider.isEventSaved(widget.event);
    final bool isAttending =
        isLoggedIn && userProvider.isEventAttending(widget.event);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, isSaved),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEventHeader(context),
                _buildEventActions(context),
                _buildEventDetails(context),
                SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildAttendButton(context, isAttending),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildAppBar(BuildContext context, bool isSaved) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(widget.event.imageUrl, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            if (widget.event.promoted)
              Positioned(
                top: 80,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        "PROMOTED",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      leading: InkWell(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: EdgeInsets.only(left: 16, top: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
      actions: [
        Container(
          margin: EdgeInsets.only(right: 16, top: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: () => _toggleSave(isSaved),
          ),
        ),
      ],
    );
  }

  Widget _buildEventHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.event.name,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today),
              SizedBox(width: 12),
              Text(
                DateFormat(
                  'EEEE, MMMM d, yyyy • h:mm a',
                ).format(widget.event.startDateTime),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on),
              SizedBox(width: 12),
              Text('${widget.event.address}, ${widget.event.city}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.euro, color: Colors.green, size: 18),
                SizedBox(width: 8),
                Text(
                  widget.event.price == 0
                      ? "Free"
                      : "${widget.event.price.toStringAsFixed(2)}€",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails(BuildContext context) {
    final description = widget.event.description;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About Event",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            isExpanded || description.length < 500
                ? description
                : "${description.substring(0, 500)}...",
            style: TextStyle(
              color: Colors.grey[300],
              fontSize: 15,
              height: 1.5,
            ),
          ),
          if (description.length > 150)
            TextButton(
              onPressed: () => setState(() => isExpanded = !isExpanded),
              child: Text(isExpanded ? "Show less" : "Read more"),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendButton(BuildContext context, bool isAttending) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 55,
          child: ElevatedButton(
            onPressed: () => _toggleAttend(isAttending),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isAttending
                      ? Colors.grey[800]
                      : Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isAttending ? "Cancel Attendance" : "Attend Event",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
