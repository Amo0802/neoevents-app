import 'package:events_amo/models/event.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationPermissionHandler {
  static const String _permissionAskedKey = 'notification_permission_asked';

  // Check if we need to ask for permission
  static Future<bool> shouldAskPermission() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_permissionAskedKey) ?? false);
  }

  // Mark that we've asked for permission
  static Future<void> markPermissionAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionAskedKey, true);
  }

  // Show a dialog asking for notification permission
  static Future<bool> requestPermission(BuildContext context) async {
    // Check permission status before showing dialog
    final shouldAsk = await shouldAskPermission();
    
    // Guard context usage after async operation
    if (!context.mounted) return false;
    
    if (!shouldAsk) {
      return true;
    }

    bool permissionGranted = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Event Reminders'),
          content: Text(
            'Allow us to send you reminders 24 hours before your events? '
            'You can change this setting later in your device settings.',
          ),
          actions: [
            TextButton(
              child: Text('No Thanks'),
              onPressed: () {
                permissionGranted = false;
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: Text('Allow'),
              onPressed: () {
                permissionGranted = true;
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );

    // Initialize notifications if permission granted
    if (permissionGranted) {
      await NotificationService().initialize();
    }

    // Mark that we've asked regardless of the answer
    await markPermissionAsked();

    return permissionGranted;
  }

  // Show a snackbar to inform the user about the notification
  static void showNotificationConfirmation(BuildContext context, Event event) {
    // Check if context is still mounted before using it
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'You\'ll receive a reminder 24 hours before ${event.name} starts',
        ),
        duration: Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}