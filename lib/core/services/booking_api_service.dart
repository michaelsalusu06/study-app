import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_config.dart';
import 'auth_state.dart';

// ─────────────────────────────────────────────────────────────
// Result types
// ─────────────────────────────────────────────────────────────

class CreateBookingResult {
  final bool success;
  final Map<String, dynamic>? booking;
  final String? errorMessage;

  const CreateBookingResult._({
    required this.success,
    this.booking,
    this.errorMessage,
  });

  factory CreateBookingResult.success(Map<String, dynamic> booking) =>
      CreateBookingResult._(success: true, booking: booking);

  factory CreateBookingResult.error(String message) =>
      CreateBookingResult._(success: false, errorMessage: message);
}

class GetBookingResult {
  final bool success;
  final Map<String, dynamic>? booking;
  final String? errorMessage;

  const GetBookingResult._({
    required this.success,
    this.booking,
    this.errorMessage,
  });

  factory GetBookingResult.success(Map<String, dynamic> booking) =>
      GetBookingResult._(success: true, booking: booking);

  factory GetBookingResult.error(String message) =>
      GetBookingResult._(success: false, errorMessage: message);
}

class GetMyBookingsResult {
  final bool success;
  final List<Map<String, dynamic>>? bookings;
  final String? errorMessage;

  const GetMyBookingsResult._({
    required this.success,
    this.bookings,
    this.errorMessage,
  });

  factory GetMyBookingsResult.success(List<Map<String, dynamic>> bookings) =>
      GetMyBookingsResult._(success: true, bookings: bookings);

  factory GetMyBookingsResult.error(String message) =>
      GetMyBookingsResult._(success: false, errorMessage: message);
}

class UpdateBookingStatusResult {
  final bool success;
  final Map<String, dynamic>? booking;
  final String? errorMessage;

  const UpdateBookingStatusResult._({
    required this.success,
    this.booking,
    this.errorMessage,
  });

  factory UpdateBookingStatusResult.success(Map<String, dynamic> booking) =>
      UpdateBookingStatusResult._(success: true, booking: booking);

  factory UpdateBookingStatusResult.error(String message) =>
      UpdateBookingStatusResult._(success: false, errorMessage: message);
}

// ─────────────────────────────────────────────────────────────
// BookingApiService — singleton
// ─────────────────────────────────────────────────────────────

/// Handles all booking-related HTTP calls for the student dashboard.
///
/// Usage:
///   final result = await BookingApiService.instance.createBooking(...);
///   if (result.success) { ... } else { print(result.errorMessage); }
class BookingApiService {
  BookingApiService._();
  static final instance = BookingApiService._();

  // ── Create a new booking ────────────────────────────────────
  /// POST /booking
  ///
  /// [tutorId]      — UUID of the tutor being booked (required)
  /// [tutorOfferId] — UUID of the specific offer (optional)
  /// [startAt]      — ISO 8601 datetime string, e.g. "2025-08-01T09:00:00.000Z"
  /// [notes]        — Optional message to the tutor
  Future<CreateBookingResult> createBooking({
    required String tutorId,
    String? tutorOfferId,
    required String startAt,
    String? notes,
  }) async {
    if (!AuthState.instance.isLoggedIn) {
      return CreateBookingResult.error('You must be logged in to book a session.');
    }

    final body = <String, dynamic>{
      'tutorId': tutorId,
      'startAt': startAt,
    };
    if (tutorOfferId != null) body['tutorOfferId'] = tutorOfferId;
    if (notes != null && notes.isNotEmpty) body['description'] = notes;

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/booking'),
        headers: AuthState.instance.authHeaders,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final booking = data['booking'] as Map<String, dynamic>? ?? data;
        return CreateBookingResult.success(booking);
      }

      final message = data['message'] ?? data['error'] ?? 'Failed to create booking.';
      return CreateBookingResult.error(message.toString());
    } catch (e) {
      return CreateBookingResult.error('Network error: $e');
    }
  }

  // ── Get a single booking by ID ──────────────────────────────
  /// GET /booking/:id
  Future<GetBookingResult> getBookingById(String bookingId) async {
    if (!AuthState.instance.isLoggedIn) {
      return GetBookingResult.error('You must be logged in.');
    }

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/booking/$bookingId'),
        headers: AuthState.instance.authHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return GetBookingResult.success(data as Map<String, dynamic>);
      }

      if (response.statusCode == 404) {
        return GetBookingResult.error('Booking not found.');
      }

      final message = data['message'] ?? data['error'] ?? 'Failed to load booking.';
      return GetBookingResult.error(message.toString());
    } catch (e) {
      return GetBookingResult.error('Network error: $e');
    }
  }

  // ── Get all bookings for the logged-in student ──────────────
  /// GET /booking/student
  ///
  /// Optional [status] filter: "pending" | "confirmed" | "completed" | "cancelled"
  Future<GetMyBookingsResult> getMyBookings({String? status}) async {
    if (!AuthState.instance.isLoggedIn) {
      return GetMyBookingsResult.error('You must be logged in.');
    }

    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('${AppConfig.apiUrl}/booking/student')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(uri, headers: AuthState.instance.authHeaders);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final list = (data as List).cast<Map<String, dynamic>>();
        return GetMyBookingsResult.success(list);
      }

      final message = data['message'] ?? data['error'] ?? 'Failed to load bookings.';
      return GetMyBookingsResult.error(message.toString());
    } catch (e) {
      return GetMyBookingsResult.error('Network error: $e');
    }
  }

  // ── Get tutor availability slots ────────────────────────────
  Future<AvailabilityResult> getTutorAvailability(String tutorId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/user/tutor/$tutorId/availability'),
        headers: AuthState.instance.authHeaders,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return AvailabilityResult.success((data as List).cast<Map<String, dynamic>>());
      }
      return AvailabilityResult.error(data['message']?.toString() ?? 'Error');
    } catch (e) {
      return AvailabilityResult.error('Network error: $e');
    }
  }

  // ── Submit a review ─────────────────────────────────────────
  Future<bool> submitReview(String bookingId, {required int rating, required String comment}) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/booking/$bookingId/review'),
        headers: AuthState.instance.authHeaders,
        body: jsonEncode({
          'rating': rating,
          'comment': comment,
        }),
      );
      return response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }
}

class AvailabilityResult {
  final bool success;
  final List<Map<String, dynamic>>? slots;
  final String? errorMessage;
  AvailabilityResult._({required this.success, this.slots, this.errorMessage});
  factory AvailabilityResult.success(List<Map<String, dynamic>> slots) =>
      AvailabilityResult._(success: true, slots: slots);
  factory AvailabilityResult.error(String msg) =>
      AvailabilityResult._(success: false, errorMessage: msg);
}