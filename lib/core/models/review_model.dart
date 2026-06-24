class ReviewModel {
  final String id;
  final String walkerId;
  final String ownerId;
  final String bookingId;
  final int rating;
  final String? comment;
  final String? ownerName;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.walkerId,
    required this.ownerId,
    required this.bookingId,
    required this.rating,
    this.comment,
    this.ownerName,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map) {
    return ReviewModel(
      id: map['id'] as String,
      walkerId: map['walker_id'] as String,
      ownerId: map['owner_id'] as String,
      bookingId: map['booking_id'] as String,
      rating: map['rating'] as int,
      comment: map['comment'] as String?,
      ownerName: map['owner_name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
