class Announcement {
  String title;
  String? image;
  String? details;
  DateTime eventDate;
  DateTime postedDate;
  String key;
  String type;

  /// Bagong Boolean field para sa pre-registration state
  bool isPreRegistered;

  Announcement({
    required this.title,
    required this.image,
    required this.details,
    required this.eventDate,
    required this.postedDate,
    required this.key,
    required this.type,
    this.isPreRegistered = false, // default na false
  });

  /// Default (empty) constructor — kailangan nating mag-initialize ng bool
  Announcement.empty()
      : key = '',
        title = '',
        image = '',
        details = '',
        eventDate = DateTime.now(),
        postedDate = DateTime.now(),
        type = '',
        isPreRegistered = false;

  /// Method to display announcement details (hindi bumabago)
  void displayAnnouncement() {
    print('Title: $title');
    print('Image Link: $image');
    print('Details: $details');
    print('Event Date: $eventDate');
    print('Posted Date: $postedDate');
    print('Key: $key');
    print('Type: $type');
    print('isPreRegistered: $isPreRegistered');
  }

  /// Pang-factory constructor mula sa JSON/map (hal. mula sa Firestore o REST API)
  factory Announcement.fromJson(Map<String, dynamic>? json) {
    final data = json ?? <String, dynamic>{};

    return Announcement(
      key: data['key'] ?? '',
      title: data['title'] ?? '',
      image: data['image'],
      details: data['details'],
      // I-parse ang dates; assume valid ISO string
      eventDate: DateTime.parse(data['eventDate'] as String),
      postedDate: DateTime.parse(data['postedDate'] as String),
      type: data['type'] ?? '',
      // Basahin ang bagong field, default sa false kung wala o null
      isPreRegistered: data['isPreRegistered'] as bool? ?? false,
    );
  }

  /// Getter para sa document ID (kung kailangan mo itong gamitin bilang id)
  /// Karaniwan, pwedeng gamitin ang `key` bilang id. Pwede mo i-override kung iba ang source ng ID.
  String get id => key;

  /// Para ma-serialize pabalik sa JSON/map (hal. i-save sa Firestore o i-send sa API)
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'image': image,
      'details': details,
      'eventDate': eventDate.toIso8601String(),
      'postedDate': postedDate.toIso8601String(),
      'type': type,
      // Idagdag ang bagong Boolean field
      'isPreRegistered': isPreRegistered,
    };
  }
}
