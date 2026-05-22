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
      'tutor_id': tutorId,
      'start_at': startAt,
    };
    if (tutorOfferId != null) body['tutor_offer_id'] = tutorOfferId;
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

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
  /// GET /booking/my
  ///
  /// Optional [status] filter: "pending" | "confirmed" | "completed" | "cancelled"
  Future<GetMyBookingsResult> getMyBookings({String? status}) async {
    if (!AuthState.instance.isLoggedIn) {
      return GetMyBookingsResult.error('You must be logged in.');
    }

    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('${AppConfig.apiUrl}/booking/my')
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

  // ── Update booking status ───────────────────────────────────
  /// PATCH /booking/:id/status
  ///
  /// [status] — one of: "confirmed" | "cancelled" | "completed"
  Future<UpdateBookingStatusResult> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    if (!AuthState.instance.isLoggedIn) {
      return UpdateBookingStatusResult.error('You must be logged in.');
    }

    try {
      final response = await http.patch(
        Uri.parse('${AppConfig.apiUrl}/booking/$bookingId/status'),
        headers: AuthState.instance.authHeaders,
        body: jsonEncode({'status': status}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final booking = data['booking'] as Map<String, dynamic>? ?? data;
        return UpdateBookingStatusResult.success(booking);
      }

      if (response.statusCode == 403) {
        return UpdateBookingStatusResult.error('You are not allowed to update this booking.');
      }

      if (response.statusCode == 404) {
        return UpdateBookingStatusResult.error('Booking not found.');
      }

      final message = data['message'] ?? data['error'] ?? 'Failed to update booking.';
      return UpdateBookingStatusResult.error(message.toString());
    } catch (e) {
      return UpdateBookingStatusResult.error('Network error: $e');
    }
  }
}