class TutorProfile {
  final String id;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final double bookPrice;
  final List<String> subjects;
  final double? overallRating;
  final int? ratingCount;

  const TutorProfile({
    required this.id,
    this.fullName,
    this.username,
    this.avatarUrl,
    this.bio,
    this.bookPrice = 0,
    this.subjects = const [],
    this.overallRating,
    this.ratingCount,
  });

  factory TutorProfile.fromJson(Map<String, dynamic> json) {
    return TutorProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      username: json['username']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      bio: json['bio']?.toString(),
      bookPrice: double.tryParse(json['book_price']?.toString() ?? '0') ?? 0,
      subjects: (json['subjects'] as List?)?.map((e) => e.toString()).toList() ?? [],
      overallRating: double.tryParse(json['overall_rating']?.toString() ?? ''),
      ratingCount: json['rating_count'] as int?,
    );
  }

  String get displayName => fullName ?? username ?? 'Tutor';

  String get formattedPrice {
    if (bookPrice == 0) return 'Free';
    return '\$${bookPrice.toStringAsFixed(0)}/hr';
  }

  String get firstSubject => subjects.isNotEmpty ? subjects.first : '';
}
