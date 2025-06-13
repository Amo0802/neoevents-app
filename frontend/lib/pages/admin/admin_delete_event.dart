import 'package:events_amo/models/event.dart';
import 'package:events_amo/providers/event_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdminDeleteEventPage extends StatefulWidget {
  const AdminDeleteEventPage({super.key});

  @override
  State<AdminDeleteEventPage> createState() => _AdminDeleteEventPageState();
}

class _AdminDeleteEventPageState extends State<AdminDeleteEventPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idController = TextEditingController();

  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;
  Event? _loadedEvent;

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _fetchEvent() async {
    if (_idController.text.isEmpty) {
      setState(() {
        _errorMessage = "Please enter an event ID";
      });
      _showSnackBar(_errorMessage!);
      return;
    }

    final eventId = int.tryParse(_idController.text);
    if (eventId == null) {
      setState(() {
        _errorMessage = "Please enter a valid event ID";
      });
      _showSnackBar(_errorMessage!);
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      await eventProvider.fetchEventById(eventId);

      if (eventProvider.selectedEvent == null) {
        setState(() {
          _errorMessage = "Event not found";
        });
        _showSnackBar(_errorMessage!);
        return;
      }

      setState(() {
        _loadedEvent = eventProvider.selectedEvent;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnackBar(_errorMessage!);
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future _deleteEvent() async {
    if (_loadedEvent == null) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Please load an event first";
      });
      _showSnackBar(_errorMessage!);
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text("Confirm Delete", style: TextStyle(color: Colors.white)),
          content: Text(
            "Are you sure you want to delete this event? This action cannot be undone.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel"),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final success = await eventProvider.deleteEvent(_loadedEvent!.id);

      if (!mounted) return;

      if (success) {
        _showSuccessDialog("Event deleted successfully");
        setState(() {
          _loadedEvent = null;
          _idController.clear();
        });
      } else {
        setState(() {
          _errorMessage = eventProvider.error ?? "Failed to delete event";
        });
        _showSnackBar(_errorMessage!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnackBar(_errorMessage!);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Success"),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Delete Event (Admin)",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchEventSection(context),
                      const SizedBox(height: 20),
                      if (_loadedEvent != null) ...[
                        _buildEventPreview(context, _loadedEvent!),
                        const SizedBox(height: 30),
                        _buildDeleteButton(context),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildSearchEventSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Event ID",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _idController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: "Enter event ID to delete",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isSearching ? null : _fetchEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isSearching
                      ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : Text("Find Event"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEventPreview(BuildContext context, Event event) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Event Details",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          Divider(color: Colors.white24, height: 24),
          _buildInfoRow("ID", "${event.id}"),
          _buildInfoRow("Name", event.name),
          _buildInfoRow("Location", "${event.address}, ${event.city}"),
          _buildInfoRow(
            "Date",
            DateFormat('MMM d, yyyy – h:mm a').format(event.startDateTime),
          ),
          _buildInfoRow("Categories", event.categories.join(', ')),
          _buildInfoRow("Price", "${event.price} €"),
          Container(
            height: 120,
            margin: EdgeInsets.only(top: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(event.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            "Warning: Deleting this event will permanently remove it from the system and cannot be undone.",
            style: TextStyle(
              color: Colors.redAccent,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: TextStyle(
                color: Colors.grey[400],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(child: Text(value, style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        icon: Icon(Icons.delete_forever),
        label: Text(
          "Delete Event",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: _isLoading ? null : _deleteEvent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}