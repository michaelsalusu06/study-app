import 'dart:convert';

import '../network/api_client.dart';
import 'auth_state.dart';

// ─── Result types ─────────────────────────────────────────────────────────────

class CreateBookingResult {
  final bool success;
  final Map<String, dynamic>? booking;
  final String? errorMessage;

  const CreateBookingResult._({required this.success, this.booking, this.errorMessage});

  factory CreateBookingResult.success(Map<String, dynamic> booking) =>
      CreateBookingResult._(success: true, booking: booking);

  factory CreateBookingResult.error(String message) =>
      CreateBookingResult._(success: false, errorMessage: message);
}

class GetBookingResult {
  final bool success;
  final Map<String, dynamic>? booking;
  final String? errorMessage;

  const GetBookingResult._({required this.success, this.booking, this.errorMessage});

  factory GetBookingResult.success(Map<String, dynamic> booking) =>
      GetBookingResult._(success: true, booking: booking);

  factory GetBookingResult.error(String message) =>
      GetBookingResult._(success: false, errorMessage: message);
}

class GetMyBookingsResult {
  final bool success;
  final List<Map<String, dynamic>>? bookings;
  final String? errorMessage;

  const GetMyBookingsResult._({required this.success, this.bookings, this.errorMessage});

  factory GetMyBookingsResult.success(List<Map<String, dynamic>> bookings) =>
      GetMyBookingsResult._(success: true, bookings: bookings);

  factory GetMyBookingsResult.error(String message) =>
      GetMyBookingsResult._(success: false, errorMessage: message);
}

class UpdateBookingStatusResult {
  final bool success;
  final Map<String, dynamic>? booking;
  final String? errorMessage;

  const UpdateBookingStatusResult._({required this.success, this.booking, this.errorMessage});

  factory UpdateBookingStatusResult.success(Map<String, dynamic> booking) =>
      UpdateBookingStatusResult._(success: true, booking: booking);

  factory UpdateBookingStatusResult.error(String message) =>
      UpdateBookingStatusResult._(success: false, errorMessage: message);
}

// ─── BookingApiService — singleton ────────────────────────────────────────────

class BookingApiService {
  BookingApiService._();
  static final instance = BookingApiService._();

  // ── POST /booking ──────────────────────────────────────────────────────────

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
      final response = await ApiClient.instance.post(
        '/booking',
        body,
        requiresAuth: true,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final booking = data['booking'] as Map<String, dynamic>? ?? data;
        return CreateBookingResult.success(booking);
      }

      final message = data['message'] ?? data['error'] ?? 'Failed to create booking.';
      return CreateBookingResult.error(message.toString());
    } on StateError catch (e) {
      return CreateBookingResult.error(e.message);
    } catch (e) {
      return CreateBookingResult.error(ApiClient.instance.friendlyError(e));
    }
  }

  // ── GET /booking/:id ───────────────────────────────────────────────────────

  Future<GetBookingResult> getBookingById(String bookingId) async {
    if (!AuthState.instance.isLoggedIn) {
      return GetBookingResult.error('You must be logged in.');
    }

    try {
      final response = await ApiClient.instance.get(
        '/booking/$bookingId',
        requiresAuth: true,
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
    } on StateError catch (e) {
      return GetBookingResult.error(e.message);
    } catch (e) {
      return GetBookingResult.error(ApiClient.instance.friendlyError(e));
    }
  }

  // ── GET /booking/student ───────────────────────────────────────────────────

  Future<GetMyBookingsResult> getMyBookings({String? status}) async {
    if (!AuthState.instance.isLoggedIn) {
      return GetMyBookingsResult.error('You must be logged in.');
    }

    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;

    try {
      final response = await ApiClient.instance.get(
        '/booking/student',
        queryParams: queryParams.isNotEmpty ? queryParams : null,
        requiresAuth: true,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final list = (data as List).cast<Map<String, dynamic>>();
        return GetMyBookingsResult.success(list);
      }

      final message = data['message'] ?? data['error'] ?? 'Failed to load bookings.';
      return GetMyBookingsResult.error(message.toString());
    } on StateError catch (e) {
      return GetMyBookingsResult.error(e.message);
    } catch (e) {
      return GetMyBookingsResult.error(ApiClient.instance.friendlyError(e));
    }
  }

  // ── GET /user/tutor/:id/availability ──────────────────────────────────────

  Future<AvailabilityResult> getTutorAvailability(String tutorId) async {
    try {
      final response = await ApiClient.instance.get(
        '/user/tutor/$tutorId/availability',
        requiresAuth: true,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AvailabilityResult.success((data as List).cast<Map<String, dynamic>>());
      }

      return AvailabilityResult.error(data['message']?.toString() ?? 'Error');
    } on StateError catch (e) {
      return AvailabilityResult.error(e.message);
    } catch (e) {
      return AvailabilityResult.error(ApiClient.instance.friendlyError(e));
    }
  }

  // ── POST /booking/:id/review ───────────────────────────────────────────────

  Future<bool> submitReview(
    String bookingId, {
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        '/booking/$bookingId/review',
        {'rating': rating, 'comment': comment},
        requiresAuth: true,
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
