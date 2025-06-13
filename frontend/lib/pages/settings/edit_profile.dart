import 'package:events_amo/providers/auth_provider.dart';
import 'package:events_amo/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLoading = false;
  int _selectedAvatarIndex = 0;

  // List of avatar options with their background colors
  final List<AvatarOption> _avatarOptions = [
    AvatarOption(backgroundCode: '0D8ABC', index: 0), // Blue
    AvatarOption(backgroundCode: 'FF5733', index: 1), // Orange/Red
    AvatarOption(backgroundCode: '28B463', index: 2), // Green
    AvatarOption(backgroundCode: '7D3C98', index: 3), // Purple
    AvatarOption(backgroundCode: 'F1C40F', index: 4), // Yellow
    AvatarOption(backgroundCode: '566573', index: 5), // Grey
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _isLoading = true;
    });

    try {
      await userProvider.fetchCurrentUser();

      final user = userProvider.currentUser;
      if (user != null) {
        // Update form fields with current user data
        setState(() {
          _nameController.text = user.name;
          _lastNameController.text = user.lastName;
          _selectedAvatarIndex = user.avatarId;
        });
      }
    } catch (e) {
      if(!mounted)return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get providers before any async operations
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Update profile details (name, lastName)
      bool profileSuccess = await userProvider.updateUserProfile(
        _nameController.text,
        _lastNameController.text,
      );

      // Update avatar if needed
      final currentUser = userProvider.currentUser;
      if (currentUser != null && _selectedAvatarIndex != currentUser.avatarId) {
        bool avatarSuccess = await userProvider.updateAvatar(
          _selectedAvatarIndex,
        );
        if (!avatarSuccess) {
          throw Exception('Failed to update avatar');
        }
      }

      // Update the auth provider to refresh user data
      if (profileSuccess) {
        await authProvider.refreshUser();
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getAvatarUrl(int index, String firstName, String lastName) {
    final background = _avatarOptions[index].backgroundCode;
    final String initials =
        ((firstName.isNotEmpty ? firstName[0] : '') +
                (lastName.isNotEmpty ? lastName[0] : ''))
            .toUpperCase();

    return 'https://ui-avatars.com/api/?background=$background&color=fff&name=$initials&size=256';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Edit Profile",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            _buildAvatarSelector(),
            SizedBox(height: 30),
            _buildTextField(
              controller: _nameController,
              label: "First Name",
              hint: "Enter your first name",
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your first name';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            _buildTextField(
              controller: _lastNameController,
              label: "Last Name",
              hint: "Enter your last name",
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your last name';
                }
                return null;
              },
            ),
            SizedBox(height: 40),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSelector() {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    // Default values in case user is null
    String firstName = _nameController.text;
    String lastName = _lastNameController.text;

    if (user != null) {
      firstName = user.name;
      lastName = user.lastName;
    }

    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: NetworkImage(
            _getAvatarUrl(_selectedAvatarIndex, firstName, lastName),
          ),
        ),
        SizedBox(height: 16),
        Text(
          "Choose an Avatar",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _avatarOptions.length,
            itemBuilder: (context, index) {
              final avatarOption = _avatarOptions[index];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedAvatarIndex = avatarOption.index;
                  });
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          _selectedAvatarIndex == avatarOption.index
                              ? Theme.of(context).colorScheme.tertiary
                              : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      _getAvatarUrl(avatarOption.index, firstName, lastName),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[500]),
            fillColor: Colors.white.withValues(alpha: 0.1),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
      ),
    );
  }
}

// Helper class to store avatar information
class AvatarOption {
  final String backgroundCode;
  final int index;

  AvatarOption({required this.backgroundCode, required this.index});
}
