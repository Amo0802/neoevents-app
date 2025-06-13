import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  // ignore: unused_element
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Support Request - NeoEvents App'
      }
    );
    
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      throw 'Could not launch email';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Help & Support",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildContactSection(context),
            SizedBox(height: 30),
            _buildFaqSection(context),
            SizedBox(height: 30),
            _buildHelpfulLinksSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Contact Us",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                "Need help? Our support team is here for you.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.email_outlined),
                label: Text("Email Support"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => _launchEmail("arminramusovic11@gmail.com"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFaqSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Frequently Asked Questions",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        SizedBox(height: 16),
        _buildFaqItem(
          context: context,
          question: "How do I create an event?",
          answer: "To create an event, tap the + button at the bottom of the screen and select either 'Official Event' or 'Community Event'. Fill in the required details and submit your event for review.",
        ),
        _buildFaqItem(
          context: context,
          question: "How do I save an event?",
          answer: "To save an event, simply tap the bookmark icon on the event card or event details page. You can view all your saved events in your profile under the 'Saved' tab.",
        ),
        _buildFaqItem(
          context: context,
          question: "Can I edit or delete an event I created?",
          answer: "Currently, you cannot directly edit events. Please contact our support team if you need to make changes to an event you've created.",
        ),
      ],
    );
  }

  Widget _buildHelpfulLinksSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Helpful Links",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        SizedBox(height: 16),
        _buildLinkTile(
          context: context,
          title: "User Guide",
          icon: Icons.menu_book_outlined,
          onTap: () => 
          // TODO
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Coming soon")),
            ),
            // _launchUrl("https://yourapp.com/guide"),
        ),
        _buildLinkTile(
          context: context,
          title: "Privacy Policy",
          icon: Icons.privacy_tip_outlined,
          onTap: () => 
          // TODO
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Coming soon")),
            ),
          // _launchUrl("https://yourapp.com/privacy"),
        ),
        _buildLinkTile(
          context: context,
          title: "Terms of Service",
          icon: Icons.description_outlined,
          onTap: () =>
          // TODO
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Coming soon")),
            ),
          //  _launchUrl("https://yourapp.com/terms"),
        ),
      ],
    );
  }

  Widget _buildFaqItem({
    required BuildContext context,
    required String question,
    required String answer,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          question,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        iconColor: Theme.of(context).colorScheme.secondary,
        collapsedIconColor: Colors.grey[400],
        children: [
          Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 16),
            child: Text(
              answer,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey[600],
        size: 16,
      ),
      onTap: onTap,
    );
  }
}