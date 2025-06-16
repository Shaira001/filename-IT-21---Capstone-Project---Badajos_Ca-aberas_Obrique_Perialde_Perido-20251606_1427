class FeedItem {
  final String key;
  final String content;
  final String? image;
  final String clientUid;
  final int commentsCount;
  final int likesCount;
  final int retweetsCount;

  FeedItem({
    required this.key,
    required this.content,
    this.image,
    required this.clientUid,
    this.commentsCount = 0,
    this.likesCount = 0,
    this.retweetsCount = 0,
  });

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    return FeedItem(
      key: json['key'] as String,
      content: json['content'] as String,
      image: json['image'] as String?,
      clientUid: json['clientUid'] as String,
      commentsCount: json['commentsCount'] ?? 0,
      likesCount: json['likesCount'] ?? 0,
      retweetsCount: json['retweetsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'content': content,
      'image': image,
      'clientUid': clientUid,
      'commentsCount': commentsCount,
      'likesCount': likesCount,
      'retweetsCount': retweetsCount,
    };
  }
}
