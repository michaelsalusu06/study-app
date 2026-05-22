// ─────────────────────────────────────────────────────────────
// Student Dashboard API Services — Barrel Export
// ─────────────────────────────────────────────────────────────
//
// Letakkan file ini di: lib/core/services/
// Lalu import semua service dari satu tempat:
//
//   import 'package:myapp/core/services/student_services.dart';
//
// ─────────────────────────────────────────────────────────────

export 'booking_api_service.dart';
export 'tutor_browse_service.dart';
export 'student_profile_service.dart';

// ═════════════════════════════════════════════════════════════
// PANDUAN PENGGUNAAN
// ═════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────
// 1. BROWSE TUTOR — TutorBrowseService
// ─────────────────────────────────────────────────────────────
//
// Ambil semua tutor:
//   final result = await TutorBrowseService.instance.getAllTutors();
//
// Cari dengan filter:
//   final result = await TutorBrowseService.instance.getTutors(
//     search: 'alice',
//     subject: 'calculus',
//     maxPrice: 150000,
//   );
//
// Detail tutor + daftar offer:
//   final result = await TutorBrowseService.instance.getTutorDetail(tutorId);
//   if (result.success) {
//     final offers = result.tutor!['tutor_offers'] as List;
//   }
//
// ─────────────────────────────────────────────────────────────
// 2. PROFIL SENDIRI — StudentProfileService
// ─────────────────────────────────────────────────────────────
//
//   final result = await StudentProfileService.instance.getMyProfile();
//   if (result.success) {
//     final name = result.profile!['full_name'];
//     final role = result.profile!['role'];   // 'STUDENT'
//   }
//
// ─────────────────────────────────────────────────────────────
// 3. BOOKING — BookingApiService
// ─────────────────────────────────────────────────────────────
//
// Buat booking baru:
//   final result = await BookingApiService.instance.createBooking(
//     tutorId: 'uuid-tutor',
//     tutorOfferId: 'uuid-offer',   // optional
//     startAt: '2025-08-01T09:00:00.000Z',
//     notes: 'Ingin belajar integral',
//   );
//
// Lihat booking saya:
//   final result = await BookingApiService.instance.getMyBookings();
//   final result = await BookingApiService.instance.getMyBookings(status: 'pending');
//
// Detail booking:
//   final result = await BookingApiService.instance.getBookingById(bookingId);
//
// Update status (batalkan):
//   final result = await BookingApiService.instance.updateBookingStatus(
//     bookingId: 'uuid-booking',
//     status: 'cancelled',  // 'confirmed' | 'cancelled' | 'completed'
//   );
//
// ─────────────────────────────────────────────────────────────
// CONTOH LENGKAP — Booking dari TutorDetailScreen
// ─────────────────────────────────────────────────────────────
//
//   Future<void> _bookSession(String offerId) async {
//     setState(() => _isLoading = true);
//
//     final result = await BookingApiService.instance.createBooking(
//       tutorId: widget.tutorId,
//       tutorOfferId: offerId,
//       startAt: _selectedDateTime.toUtc().toIso8601String(),
//       notes: _notesController.text,
//     );
//
//     if (!mounted) return;
//     setState(() => _isLoading = false);
//
//     if (result.success) {
//       final bookingId = result.booking!['id'];
//       Navigator.of(context).pushReplacementNamed(
//         '/payment',
//         arguments: {'bookingId': bookingId},
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(result.errorMessage!)),
//       );
//     }
//   }