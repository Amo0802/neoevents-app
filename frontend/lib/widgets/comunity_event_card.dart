import 'package:events_amo/models/event.dart';
import 'package:events_amo/pages/events_detail_page.dart';
import 'package:events_amo/pages/login_page.dart';
import 'package:events_amo/providers/auth_provider.dart';
import 'package:events_amo/providers/user_provider.dart';
import 'package:events_amo/utils/notification_permission_handler.dart';
import 'package:events_amo/utils/width_constraint_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CommunityEventCard extends StatefulWidget {
  final Event event;

  const CommunityEventCard({super.key, required this.event});

  @override
  State<CommunityEventCard> createState() => _CommunityEventCardState();
}

class _CommunityEventCardState extends State<CommunityEventCard> {
  bool _isProcessing = false;

  void _toggleSave(bool isSaved) {
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WidthConstraintWrapper(child: EventDetailPage(event: widget.event)),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Color(0xFF1F2533), Color(0xFF131824)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with gradient overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Image.network(
                    widget.event.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                // Category badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        widget.event.categoryLabels,
                        context,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.event.categoryLabels.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                // Date badge
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.tertiary.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'MMM d',
                          ).format(widget.event.startDateTime),
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
            // Content
            Padding(
              padding: EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.event.name,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        widget.event.location,
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _isProcessing
                                  ? null
                                  : () => _toggleAttend(isAttending),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isAttending
                                    ? Colors.grey[700]
                                    : Theme.of(context).colorScheme.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            isAttending ? "Cancel Attend" : "Attend",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      IconButton(
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color:
                              isSaved
                                  ? Theme.of(context).colorScheme.tertiary
                                  : Colors.grey[400],
                        ),
                        onPressed:
                            _isProcessing ? null : () => _toggleSave(isSaved),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category, BuildContext context) {
    switch (category) {
      case 'wellness':
        return Colors.green;
      case 'social':
        return Colors.blue;
      case 'arts':
        return Colors.purple;
      case 'sports':
        return Colors.orange;
      case 'learning':
        return Colors.red;
      case 'food':
        return Colors.amber;
      case 'music':
        return Colors.pink;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
