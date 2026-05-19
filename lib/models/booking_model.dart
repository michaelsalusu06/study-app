/// Status of a tutoring session booking.
enum BookingStatus { upcoming, ongoing, completed, cancelled }

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.upcoming:   return 'Upcoming';
      case BookingStatus.ongoing:    return 'Ongoing';
      case BookingStatus.completed:  return 'Completed';
      case BookingStatus.cancelled:  return 'Cancelled';
    }
  }
}

class Booking {
  final String id;
  final String tutorName;
  final String? tutorAvatarUrl;
  final String subject;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final double price;

  const Booking({
    required this.id,
    required this.tutorName,
    this.tutorAvatarUrl,
    required this.subject,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.price,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id:             json['id']?.toString() ?? '',
      tutorName:      json['tutor_name']?.toString() ?? 'Tutor',
      tutorAvatarUrl: json['tutor_avatar_url']?.toString(),
      subject:        json['subject']?.toString() ?? '',
      date:           DateTime.parse(json['date'].toString()),
      startTime:      DateTime.parse(json['start_time'].toString()),
      endTime:        DateTime.parse(json['end_time'].toString()),
      status:         _parseStatus(json['status']?.toString()),
      price:          double.tryParse(json['price']?.toString() ?? '0') ?? 0,
    );
  }

  static BookingStatus _parseStatus(String? value) {
    switch (value) {
      case 'ongoing':   return BookingStatus.ongoing;
      case 'completed': return BookingStatus.completed;
      case 'cancelled': return BookingStatus.cancelled;
      default:          return BookingStatus.upcoming;
    }
  }

  String get formattedPrice => price == 0 ? 'Free' : '\$${price.toStringAsFixed(0)}';

  /// e.g. "09:00 – 10:00"
  String get timeRange {
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${fmt(startTime)} – ${fmt(endTime)}';
  }

  /// Duration in minutes
  int get durationMinutes => endTime.difference(startTime).inMinutes;
}