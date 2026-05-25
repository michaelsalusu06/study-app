import 'dart:convert';

import '../network/api_client.dart';

// ─── Result types ─────────────────────────────────────────────────────────────

class GetTutorsResult {
  final bool success;
  final List<Map<String, dynamic>>? tutors;
  final String? errorMessage;

  const GetTutorsResult._({required this.success, this.tutors, this.errorMessage});

  factory GetTutorsResult.success(List<Map<String, dynamic>> tutors) =>
      GetTutorsResult._(success: true, tutors: tutors);

  factory GetTutorsResult.error(String message) =>
      GetTutorsResult._(success: false, errorMessage: message);
}

class GetTutorDetailResult {
  final bool success;
  final Map<String, dynamic>? tutor;
  final String? errorMessage;

  const GetTutorDetailResult._({required this.success, this.tutor, this.errorMessage});

  factory GetTutorDetailResult.success(Map<String, dynamic> tutor) =>
      GetTutorDetailResult._(success: true, tutor: tutor);

  factory GetTutorDetailResult.error(String message) =>
      GetTutorDetailResult._(success: false, errorMessage: message);
}

// ─── TutorBrowseService — singleton ───────────────────────────────────────────

/// Handles tutor discovery API calls.
/// All endpoints are public (no auth required for browsing).
class TutorBrowseService {
  TutorBrowseService._();
  static final instance = TutorBrowseService._();

  // ── GET /user/tutors/all ───────────────────────────────────────────────────

  Future<GetTutorsResult> getAllTutors() async {
    try {
      final response = await ApiClient.instance.get('/user/tutors/all');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return GetTutorsResult.success((data as List).cast<Map<String, dynamic>>());
      }

      return GetTutorsResult.error('Failed to load tutors.');
    } on StateError catch (e) {
      return GetTutorsResult.error(e.message);
    } catch (e) {
      return GetTutorsResult.error(ApiClient.instance.friendlyError(e));
    }
  }

  // ── GET /user/tutors?search=&subject=&maxCoins= ────────────────────────────

  Future<GetTutorsResult> getTutors({
    String? search,
    String? subject,
    double? maxPrice,
  }) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;
    if (maxPrice != null) queryParams['maxCoins'] = maxPrice.toStringAsFixed(0);

    try {
      final response = await ApiClient.instance.get(
        '/user/tutors',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return GetTutorsResult.success((data as List).cast<Map<String, dynamic>>());
      }

      return GetTutorsResult.error('Failed to search tutors.');
    } on StateError {
      return GetTutorsResult.error('Please wait before searching again.');
    } catch (e) {
      return GetTutorsResult.error(ApiClient.instance.friendlyError(e));
    }
  }

  // ── GET /user/tutor/:id ────────────────────────────────────────────────────

  Future<GetTutorDetailResult> getTutorDetail(String tutorId) async {
    try {
      final response = await ApiClient.instance.get('/user/tutor/$tutorId');
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return GetTutorDetailResult.success(data as Map<String, dynamic>);
      }

      if (response.statusCode == 404) {
        return GetTutorDetailResult.error('Tutor not found.');
      }

      final message = data['message'] ?? data['error'] ?? 'Failed to load tutor.';
      return GetTutorDetailResult.error(message.toString());
    } on StateError catch (e) {
      return GetTutorDetailResult.error(e.message);
    } catch (e) {
      return GetTutorDetailResult.error(ApiClient.instance.friendlyError(e));
    }
  }
}
