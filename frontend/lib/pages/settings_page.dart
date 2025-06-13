import 'package:events_amo/pages/main_page.dart';
import 'package:events_amo/pages/settings/about.dart';
// import 'package:events_amo/pages/settings/change_email.dart';
import 'package:events_amo/pages/settings/change_password.dart';
import 'package:events_amo/pages/settings/edit_profile.dart';
import 'package:events_amo/pages/settings/help_and_support.dart';
import 'package:events_amo/pages/settings/notification_page.dart';
import 'package:events_amo/utils/width_constraint_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:events_amo/providers/auth_provider.dart';
import 'package:events_amo/providers/user_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Color(0xFF1A1F38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Log Out",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "Are you sure you want to log out?",
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Close dialog first
              Navigator.of(dialogContext).pop();
              
              // Store navigator reference before async work
              final navigator = Navigator.of(context);
              final authProvider = context.read<AuthProvider>();
              
              // Process logout without using context afterward
              () async {
                await authProvider.logout();
                
                // Use stored navigator reference
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WidthConstraintWrapper(child: MainPage(initialTabIndex: 0))),
                  (route) => false,
                );
              }();
            },
            child: Text("Log Out", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Color(0xFF1A1F38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          "Delete Account",
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "This action cannot be undone. All your data will be permanently deleted. Are you sure?",
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Close dialog first
              Navigator.of(dialogContext).pop();
              
              // Store navigator and providers before async work
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final userProvider = context.read<UserProvider>();
              final authProvider = context.read<AuthProvider>();
              
              // Process deletion without using context afterward
              () async {
                final success = await userProvider.deleteCurrentUser();
                
                if (success) {
                  await authProvider.logout();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const WidthConstraintWrapper(child: MainPage(initialTabIndex: 0))),
                    (route) => false,
                  );
                } else {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text("Failed to delete account")),
                  );
                }
              }();
            },
            child: Text(
              "Delete Account",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color ?? Theme.of(context).colorScheme.secondary,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (iconColor ?? theme.colorScheme.secondary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? theme.colorScheme.secondary),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.white,
        ),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[600]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.grey[800], thickness: 1, height: 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Settings",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: ListView(
          children: [
            _buildSectionHeader("Account"),
            _buildSettingTile(
              icon: Icons.person_outline,
              title: "Edit Profile",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WidthConstraintWrapper(child: EditProfilePage())),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.notifications_outlined,
              title: "Notifications",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WidthConstraintWrapper(child: NotificationsPage())),
                );
              },
            ),
            // _buildSettingTile(
            //   icon: Icons.email_outlined,
            //   title: "Change Email",
            //   onTap: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(builder: (context) => const WidthConstraintWrapper(child: ChangeEmailPage())),
            //     );
            //   },
            // ),
            _buildSettingTile(
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WidthConstraintWrapper(child: ChangePasswordPage())),
                );
              },
            ),
            _buildDivider(),
            _buildSectionHeader("App Settings"),
            _buildSettingTile(
              icon: Icons.language_outlined,
              title: "Language",
              onTap: () {
                // TODO: Language selection will be implemented later
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Language settings coming soon")),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.help_outline,
              title: "Help & Support",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WidthConstraintWrapper(child: HelpSupportPage())),
                );
              },
            ),
            _buildSettingTile(
              icon: Icons.info_outline,
              title: "About",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WidthConstraintWrapper(child: AboutPage())),
                );
              },
            ),
            _buildDivider(),
            _buildSectionHeader("Danger Zone", color: Colors.redAccent),
            _buildSettingTile(
              icon: Icons.logout,
              title: "Log out",
              iconColor: Colors.redAccent,
              textColor: Colors.redAccent,
              onTap: _showLogoutDialog,
            ),
            _buildSettingTile(
              icon: Icons.delete_forever_outlined,
              title: "Delete Account",
              iconColor: Colors.redAccent,
              textColor: Colors.redAccent,
              onTap: _showDeleteAccountDialog,
            ),
          ],
        ),
      ),
    );
  }
}