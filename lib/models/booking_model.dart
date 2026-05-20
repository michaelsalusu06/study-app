enum BookingStatus { pending, confirmed, completed, cancelled, declined }

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:   return 'Pending';
      case BookingStatus.confirmed: return 'Confirmed';
      case BookingStatus.completed: return 'Completed';
      case BookingStatus.cancelled: return 'Cancelled';
      case BookingStatus.declined:  return 'Declined';
    }
  }
}

class Booking {
  final String id;
  final String tutorName;
  final String? tutorAvatarUrl;

  // Konten
  final String title;
  final String? description;
  final String subject;

  // Jadwal
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String dayOfWeek;        // e.g. "Monday"
  final String defaultStartTime; // e.g. "09:00"

  // Pembayaran
  final double price;
  final int coinAmount;

  final BookingStatus status;

  const Booking({
    required this.id,
    required this.tutorName,
    this.tutorAvatarUrl,
    required this.title,
    this.description,
    required this.subject,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    required this.defaultStartTime,
    required this.price,
    this.coinAmount = 0,
    required this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id:               json['id']?.toString() ?? '',
      tutorName:        json['tutor_name']?.toString() ?? 'Tutor',
      tutorAvatarUrl:   json['tutor_avatar_url']?.toString(),
      title:            json['title']?.toString() ?? '',
      description:      json['description']?.toString(),
      subject:          json['subject']?.toString() ?? '',
      date:             DateTime.parse(json['date'].toString()),
      startTime:        DateTime.parse(json['start_time'].toString()),
      endTime:          DateTime.parse(json['end_time'].toString()),
      dayOfWeek:        json['day_of_week']?.toString() ?? '',
      defaultStartTime: json['default_start_time']?.toString() ?? '',
      price:            double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      coinAmount:       int.tryParse(json['coin_amount']?.toString() ?? '0') ?? 0,
      status:           _parseStatus(json['status']?.toString()),
    );
  }

  static BookingStatus _parseStatus(String? value) {
    switch (value) {
      case 'confirmed': return BookingStatus.confirmed;
      case 'completed': return BookingStatus.completed;
      case 'cancelled': return BookingStatus.cancelled;
      case 'declined':  return BookingStatus.declined;
      default:          return BookingStatus.pending;
    }
  }

  String get formattedPrice => price == 0 ? 'Free' : '\$${price.toStringAsFixed(0)}';
  String get formattedCoins => '$coinAmount coins';

  String get timeRange {
    String fmt(DateTime dt) =>
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${fmt(startTime)} – ${fmt(endTime)}';
  }

  int get durationMinutes => endTime.difference(startTime).inMinutes;
  String get formattedDuration => '$durationMinutes min';
}