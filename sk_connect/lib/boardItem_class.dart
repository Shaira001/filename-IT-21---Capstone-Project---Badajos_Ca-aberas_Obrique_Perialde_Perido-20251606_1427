class BoardItem {
  String key;
  List<String> images;
  String title;
  String description; 

  BoardItem({
    required this.key,
    required this.images,
    required this.title,
    required this.description,
  });

  factory BoardItem.fromJson(Map<String, dynamic> json) {
    return BoardItem(
      key: json['key'] as String,
      images: List<String>.from(json['images'] ?? []),
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'images': images,
      'title': title,
      'description': description,
    };
  }
}
