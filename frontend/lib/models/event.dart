class Event {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final String city;
  final String address;
  final DateTime startDateTime;
  final double price;
  final List<String> categories;
  final int priority;
  final bool mainEvent;
  final bool promoted;
  
  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.city,
    required this.address,
    required this.startDateTime,
    required this.price,
    required this.categories,
    this.priority = 0,
    this.mainEvent = false,
    this.promoted = false,
  });

  Event copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    String? city,
    String? address,
    DateTime? startDateTime,
    double? price,
    List<String>? categories,
    int? priority,
    bool? mainEvent,
    bool? promoted,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      city: city ?? this.city,
      address: address ?? this.address,
      startDateTime: startDateTime ?? this.startDateTime,
      price: price ?? this.price,
      categories: categories ?? this.categories,
      priority: priority ?? this.priority,
      mainEvent: mainEvent ?? this.mainEvent,
      promoted: promoted ?? this.promoted,
    );
  }

  factory Event.forSubmission({
    required String name,
    required String description,
    required String address,
    required DateTime startDateTime,
    required double price,
    required List<String> categories,
  }) {
    return Event(
      id: -1, // or -1, or any dummy ID
      name: name,
      description: description,
      imageUrl: "", // since backend doesn't use it
      city: "",
      address: address,
      startDateTime: startDateTime,
      price: price,
      categories: categories,
      priority: 0,
      mainEvent: false,
      promoted: false,
    );
  }

  
  String get formattedDate => '${startDateTime.day}/${startDateTime.month}/${startDateTime.year}';

  String get location => '$address, ${city.toString().split('.').last}';

  String get categoryLabels => categories.map((e) => e.toString().split('.').last).join(', ');

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      city: json['city'], // expects "PODGORICA" etc.
      address: json['address'],
      startDateTime: DateTime.parse(json['startDateTime']),
      price: json['price'] is int ? (json['price'] as int).toDouble() : json['price'],
      categories: List<String>.from(json['categories']), // expects ["MUSIC", "SPORTS"] etc.
      priority: json['priority'] ?? 0,
      mainEvent: json['mainEvent'] ?? false,
      promoted: json['promoted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'city': city.toUpperCase(), // match enum values in backend
      'address': address,
      'startDateTime': startDateTime.toIso8601String(),
      'price': price,
      'categories': categories.map((e) => e.toUpperCase()).toList(), // send in UPPERCASE
      'priority': priority,
      'mainEvent': mainEvent,
      'promoted': promoted,
    };
  }
}