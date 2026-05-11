import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_config.dart';
import '../../data/dummy_data.dart';
import '../../models/tutor_profile.dart';
import 'auth_state.dart';

class UserApiService {
  UserApiService._();
  static final UserApiService instance = UserApiService._();

  // ─── Update Profile ───────────────────────────────────────────────────────

  Future<UpdateProfileResult> updateProfile({
    String? username,
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? role,
  }) async {
    if (!AuthState.instance.isLoggedIn) {
      return UpdateProfileResult.error('Not authenticated. Please log in first.');
    }

    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (fullName != null) body['full_name'] = fullName;
    if (bio != null) body['bio'] = bio;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (role != null) body['role'] = role;

    try {
      final response = await http
          .patch(
            Uri.parse('${AppConfig.apiUrl}/user/update/profile'),
            headers: AuthState.instance.authHeaders,
            body: jsonEncode(body),
          )
          .timeout(AppConfig.requestTimeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return UpdateProfileResult.success(data['user'] as Map<String, dynamic>);
      }

      final message = data['message']?.toString() ?? 'Update failed (${response.statusCode})';
      return UpdateProfileResult.error(message);
    } catch (e) {
      return UpdateProfileResult.error('Network error. Please try again.');
    }
  }

  // ─── Get Tutors ───────────────────────────────────────────────────────────

  Future<TutorListResult> getTutors({
    String? search,
    String? subject,
    double? maxPrice,
  }) async {
    if (AppConfig.useMock) {
      await Future.delayed(const Duration(milliseconds: 700));
      final mockTutors = DummyData.teachers.map((t) => TutorProfile(
            id: t.id,
            fullName: t.user.name,
            subjects: t.expertise,
            bookPrice: t.hourlyRate ?? 0,
            overallRating: t.rating,
            ratingCount: t.totalReviews,
            avatarUrl: null,
          )).toList();
      return TutorListResult.success(mockTutors);
    }

    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;
    if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();

    final uri = Uri.parse('${AppConfig.apiUrl}/user/tutors')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return TutorListResult.success(
          list.map((e) => TutorProfile.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }

      return TutorListResult.error('Failed to load tutors (${response.statusCode})');
    } catch (e) {
      return TutorListResult.error('Network error. Please try again.');
    }
  }
}

// ─── Result Models ────────────────────────────────────────────────────────────

class UpdateProfileResult {
  final bool success;
  final Map<String, dynamic>? user;
  final String? errorMessage;

  const UpdateProfileResult._({
    required this.success,
    this.user,
    this.errorMessage,
  });

  factory UpdateProfileResult.success(Map<String, dynamic> user) =>
      UpdateProfileResult._(success: true, user: user);

  factory UpdateProfileResult.error(String message) =>
      UpdateProfileResult._(success: false, errorMessage: message);
}

class TutorListResult {
  final bool success;
  final List<TutorProfile>? tutors;
  final String? errorMessage;

  const TutorListResult._({
    required this.success,
    this.tutors,
    this.errorMessage,
  });

  factory TutorListResult.success(List<TutorProfile> tutors) =>
      TutorListResult._(success: true, tutors: tutors);

  factory TutorListResult.error(String message) =>
      TutorListResult._(success: false, errorMessage: message);
}
