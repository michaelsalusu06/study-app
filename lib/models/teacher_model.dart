import 'user_model.dart';

/// Teacher model extending user with teacher-specific data
class TeacherModel {
  const TeacherModel({
    required this.id,
    required this.user,
    this.expertise = const [],
    this.education,
    this.experience,
    this.hourlyRate,
    this.totalStudents = 0,
    this.totalCourses = 0,
    this.totalReviews = 0,
    this.rating = 0.0,
    this.subscriberCount = 0,
    this.isSubscribed = false,
    this.bio,
  });

  final String id;
  final UserModel user;
  final List<String> expertise;
  final String? education;
  final String? experience;
  final double? hourlyRate;
  final int totalStudents;
  final int totalCourses;
  final int totalReviews;
  final double rating;
  final int subscriberCount;
  final bool isSubscribed;
  final String? bio;

  /// Get formatted hourly rate
  String get formattedHourlyRate {
    if (hourlyRate == null) return '';
    return '\$${hourlyRate!.toStringAsFixed(2)}/hr';
  }

  /// Copy with new values
  TeacherModel copyWith({
    String? id,
    UserModel? user,
    List<String>? expertise,
    String? education,
    String? experience,
    double? hourlyRate,
    int? totalStudents,
    int? totalCourses,
    int? totalReviews,
    double? rating,
    int? subscriberCount,
    bool? isSubscribed,
    String? bio,
  }) {
    return TeacherModel(
      id: id ?? this.id,
      user: user ?? this.user,
      expertise: expertise ?? this.expertise,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      totalStudents: totalStudents ?? this.totalStudents,
      totalCourses: totalCourses ?? this.totalCourses,
      totalReviews: totalReviews ?? this.totalReviews,
      rating: rating ?? this.rating,
      subscriberCount: subscriberCount ?? this.subscriberCount,
      isSubscribed: isSubscribed ?? this.isSubscribed,
      bio: bio ?? this.bio,
    );
  }
}
