class User {
  final int? id;
  final String name;
  final String lastName;
  final String email;
  final bool isAdmin;
  final int avatarId; // New field for avatar

  User({
    this.id,
    required this.name,
    required this.lastName,
    required this.email,
    this.isAdmin = false,
    this.avatarId = 0, // Default avatar ID is 0
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      lastName: json['lastName'],
      email: json['email'],
      isAdmin: json['admin'] ?? false,
      avatarId: json['avatarId'] ?? 0, // Parse avatarId from JSON response
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'lastName': lastName,
        'email': email,
        'isAdmin': isAdmin,
        'avatarId': avatarId,
      };
      
  /// Get avatar URL based on the avatarId
  String getAvatarUrl() {
    // You can customize this to use different avatar providers or your own server
    // List of avatar background colors
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
    final String initials = ((name.isNotEmpty ? name[0] : '') + 
                            (lastName.isNotEmpty ? lastName[0] : '')).toUpperCase();
    
    // Return the URL for the UI Avatars service
    return 'https://ui-avatars.com/api/?background=$background&color=fff&name=$initials&size=256';
  }
  
  /// Create a copy of this user with updated fields
  User copyWith({
    int? id,
    String? name,
    String? lastName,
    String? email,
    bool? isAdmin,
    int? avatarId,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      isAdmin: isAdmin ?? this.isAdmin,
      avatarId: avatarId ?? this.avatarId,
    );
  }
}