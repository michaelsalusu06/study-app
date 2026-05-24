import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';
import 'auth_state.dart';

// ─────────────────────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────────────────────

class GetTutorsResult {
  final bool success;
  final List<Map<String, dynamic>>? tutors;
  final String? errorMessage;

  const GetTutorsResult._({
    required this.success,
    this.tutors,
    this.errorMessage,
  });

  factory GetTutorsResult.success(List<Map<String, dynamic>> tutors) =>
      GetTutorsResult._(success: true, tutors: tutors);

  factory GetTutorsResult.error(String message) =>
      GetTutorsResult._(success: false, errorMessage: message);
}

class GetTutorDetailResult {
  final bool success;
  final Map<String, dynamic>? tutor;
  final String? errorMessage;

  const GetTutorDetailResult._({
    required this.success,
    this.tutor,
    this.errorMessage,
  });

  factory GetTutorDetailResult.success(Map<String, dynamic> tutor) =>
      GetTutorDetailResult._(success: true, tutor: tutor);

  factory GetTutorDetailResult.error(String message) =>
      GetTutorDetailResult._(success: false, errorMessage: message);
}

// ─────────────────────────────────────────────────────────────
// TutorBrowseService — singleton
// ─────────────────────────────────────────────────────────────

/// Handles tutor discovery API calls for the student dashboard.
///
/// All endpoints are public (no auth required), so students can
/// browse tutors even before logging in.
///
/// Usage:
///   final result = await TutorBrowseService.instance.getTutors(search: 'math');
///   if (result.success) {
///     for (final tutor in result.tutors!) { ... }
///   }
class TutorBrowseService {
  TutorBrowseService._();
  static final instance = TutorBrowseService._();

  // ── Get all tutors (no filter) ──────────────────────────────
  /// GET /user/tutors/all
  ///
  /// Returns every tutor profile. Use [getTutors] if you need filtering.
  Future<GetTutorsResult> getAllTutors() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/user/tutors/all'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final list = (data as List).cast<Map<String, dynamic>>();
        return GetTutorsResult.success(list);
      }

      return GetTutorsResult.error('Failed to load tutors.');
    } catch (e) {
      return GetTutorsResult.error('Network error: $e');
    }
  }

  // ── Search & filter tutors ──────────────────────────────────
  /// GET /user/tutors?search=...&subject=...&maxPrice=...
  ///
  /// All parameters are optional and combinable:
  ///   [search]   — case-insensitive match on full_name or username
  ///   [subject]  — exact subject slug, e.g. "calculus"
  ///   [maxPrice] — upper bound on book_price
  ///
  /// Example:
  ///   final result = await TutorBrowseService.instance.getTutors(
  ///     search: 'alice',
  ///     subject: 'calculus',
  ///     maxPrice: 150000,
  ///   );
  Future<GetTutorsResult> getTutors({
    String? search,
    String? subject,
    double? maxPrice,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (subject != null && subject.isNotEmpty) queryParams['subject'] = subject;
      if (maxPrice != null) queryParams['maxCoins'] = maxPrice.toStringAsFixed(0);

      final uri = Uri.parse('${AppConfig.apiUrl}/user/tutors')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final list = (data as List).cast<Map<String, dynamic>>();
        return GetTutorsResult.success(list);
      }

      return GetTutorsResult.error('Failed to search tutors.');
    } catch (e) {
      return GetTutorsResult.error('Network error: $e');
    }
  }

  // ── Get single tutor detail + their offers ──────────────────
  /// GET /user/tutor/:id
  ///
  /// Returns the tutor's full profile including active [tutor_offers].
  ///
  /// The [tutor_offers] list in the response looks like:
  ///   [{
  ///     "id": "uuid",
  ///     "title": "Calculus Basics — 1 Hour",
  ///     "summary": "...",
  ///     "price_per_hour": 150000,
  ///     "duration_minutes": 60,
  ///   }]
  Future<GetTutorDetailResult> getTutorDetail(String tutorId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/user/tutor/$tutorId'),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return GetTutorDetailResult.success(data as Map<String, dynamic>);
      }

      if (response.statusCode == 404) {
        return GetTutorDetailResult.error('Tutor not found.');
      }

      final message = data['message'] ?? data['error'] ?? 'Failed to load tutor.';
      return GetTutorDetailResult.error(message.toString());
    } catch (e) {
      return GetTutorDetailResult.error('Network error: $e');
    }
  }
}