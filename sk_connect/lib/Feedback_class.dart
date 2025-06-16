class Feedback {
  final String key;
  final int rating;
  final String? comment;
  final String clientUid;

  Feedback({
    required this.key,
    required this.rating,
    this.comment,
    required this.clientUid,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      key: json['key'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      clientUid: json['clientUid'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'rating': rating,
      'comment': comment,
      'clientUid': clientUid,
    };
  }
}
