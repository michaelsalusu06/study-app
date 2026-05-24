import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_config.dart';
import '../../data/dummy_data.dart';
import '../../models/booking_model.dart';
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
    if (maxPrice != null) queryParams['maxCoins'] = maxPrice.toString();

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

  // ─── Get Tutor Detail ─────────────────────────────────────────────────────

  Future<TutorDetailResult> getTutorDetail(String tutorId) async {
    final uri = Uri.parse('${AppConfig.apiUrl}/user/tutor/$tutorId');

    try {
      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return TutorDetailResult.success(data);
      }

      return TutorDetailResult.error('Failed to load tutor (${response.statusCode})');
    } catch (e) {
      return TutorDetailResult.error('Network error. Please try again.');
    }
  }

  // ─── Get Student Bookings ─────────────────────────────────────────────────

  Future<BookingListResult> getStudentBookings({
    String? status,
    String? from,
    String? to,
  }) async {
    if (!AuthState.instance.isLoggedIn) {
      return BookingListResult.error('Not authenticated.');
    }

    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;

    final uri = Uri.parse('${AppConfig.apiUrl}/booking/student')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

    try {
      final response = await http
          .get(uri, headers: AuthState.instance.authHeaders)
          .timeout(AppConfig.requestTimeout);

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return BookingListResult.success(
          list.map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }

      return BookingListResult.error('Failed to load bookings (${response.statusCode})');
    } catch (e) {
      return BookingListResult.error('Network error. Please try again.');
    }
  }

  // ─── Get Join Info (Jitsi) ────────────────────────────────────────────────

  Future<JoinInfoResult> getJoinInfo(String bookingId) async {
    if (!AuthState.instance.isLoggedIn) {
      return JoinInfoResult.error('Not authenticated.');
    }

    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiUrl}/booking/$bookingId/join'),
            headers: AuthState.instance.authHeaders,
          )
          .timeout(AppConfig.requestTimeout);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return JoinInfoResult.success(
          meetingUrl: data['meeting_url'].toString(),
          roomPassword: data['room_password']?.toString(),
        );
      }

      final msg = data['message']?.toString() ?? 'Cannot join (${response.statusCode})';
      return JoinInfoResult.error(msg);
    } catch (e) {
      return JoinInfoResult.error('Network error. Please try again.');
    }
  }

  // ─── Get Chat Thread List ─────────────────────────────────────────────────

  Future<ChatThreadListResult> getChatThreadList() async {
    if (!AuthState.instance.isLoggedIn) {
      return ChatThreadListResult.error('Not authenticated.');
    }

    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiUrl}/messages/conversations'),
            headers: AuthState.instance.authHeaders,
          )
          .timeout(AppConfig.requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data is List) {
          final list = data.whereType<Map<String, dynamic>>().toList();
          return ChatThreadListResult.success(
            list.map((e) => ChatThread.fromJson(e)).toList(),
          );
        }
        return ChatThreadListResult.success([]);
      }

      return ChatThreadListResult.error('Failed to load chats (${response.statusCode})');
    } catch (e) {
      return ChatThreadListResult.error('Network error. Please try again.');
    }
  }

  // ─── Get Chat Thread ──────────────────────────────────────────────────────

  Future<ChatMessageListResult> getChatThread(String otherId) async {
    if (!AuthState.instance.isLoggedIn) {
      return ChatMessageListResult.error('Not authenticated.');
    }

    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiUrl}/messages/conversation/$otherId'),
            headers: AuthState.instance.authHeaders,
          )
          .timeout(AppConfig.requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final messagesData = data['messages'];
        if (messagesData is List) {
          final messagesList = messagesData.whereType<Map<String, dynamic>>().toList();
          return ChatMessageListResult.success(
            messagesList.map((e) => ChatMessage.fromJson(e)).toList(),
          );
        }
        return ChatMessageListResult.success([]);
      }

      return ChatMessageListResult.error('Failed to load messages (${response.statusCode})');
    } catch (e) {
      return ChatMessageListResult.error('Network error. Please try again.');
    }
  }

  // ─── Send Message ─────────────────────────────────────────────────────────

  Future<SendMessageResult> sendMessage({
    required String toId,
    required String content,
    String? bookingId,
  }) async {
    if (!AuthState.instance.isLoggedIn) {
      return SendMessageResult.error('Not authenticated.');
    }

    final body = <String, dynamic>{
      'to_id': toId,
      'content': content,
      if (bookingId != null) 'booking_id': bookingId,
    };

    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiUrl}/messages'),
            headers: AuthState.instance.authHeaders,
            body: jsonEncode(body),
          )
          .timeout(AppConfig.requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data is Map<String, dynamic>) {
          return SendMessageResult.success(ChatMessage.fromJson(data));
        }
      }

      return SendMessageResult.error(
          data['message']?.toString() ?? 'Failed to send (${response.statusCode})');
    } catch (e) {
      return SendMessageResult.error('Network error. Please try again.');
    }
  }
  // ─── Coin History ─────────────────────────────────────────────────────────

  Future<CoinHistoryResult> getCoinHistory() async {
    if (!AuthState.instance.isLoggedIn) return CoinHistoryResult.error('Not authenticated.');
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/coins/history'),
        headers: AuthState.instance.authHeaders,
      );
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List;
        return CoinHistoryResult.success(list.cast<Map<String, dynamic>>());
      }
      return CoinHistoryResult.error('Failed to load history (${response.statusCode})');
    } catch (e) {
      return CoinHistoryResult.error('Network error.');
    }
  }

  // ─── Booking Actions ──────────────────────────────────────────────────────

  Future<SimpleResult> cancelBooking(String bookingId) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConfig.apiUrl}/booking/$bookingId/cancel'),
        headers: AuthState.instance.authHeaders,
      );
      return SimpleResult(success: response.statusCode == 200, message: jsonDecode(response.body)['message']?.toString());
    } catch (_) {
      return SimpleResult(success: false, message: 'Network error.');
    }
  }

  Future<SimpleResult> proposeReschedule(String bookingId, DateTime newStart) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConfig.apiUrl}/booking/$bookingId/propose-reschedule'),
        headers: AuthState.instance.authHeaders,
        body: jsonEncode({'newStartAt': newStart.toIso8601String()}),
      );
      return SimpleResult(success: response.statusCode == 200, message: jsonDecode(response.body)['message']?.toString());
    } catch (_) {
      return SimpleResult(success: false, message: 'Network error.');
    }
  }

  // ─── Avatar Upload ────────────────────────────────────────────────────────

  Future<SimpleResult> updateAvatar(String imageUrl) async {
    // Note: This assumes the image is already uploaded or we're sending a URL.
    // Real multipart upload would use http.MultipartRequest.
    return updateProfile(avatarUrl: imageUrl).then((res) => SimpleResult(success: res.success, message: res.errorMessage));
  }
}

// ─── Result Models ────────────────────────────────────────────────────────────

class SimpleResult {
  final bool success;
  final String? message;
  SimpleResult({required this.success, this.message});
}

class CoinHistoryResult {
  final bool success;
  final List<Map<String, dynamic>>? history;
  final String? errorMessage;
  CoinHistoryResult._({required this.success, this.history, this.errorMessage});
  factory CoinHistoryResult.success(List<Map<String, dynamic>> data) => CoinHistoryResult._(success: true, history: data);
  factory CoinHistoryResult.error(String msg) => CoinHistoryResult._(success: false, errorMessage: msg);
}

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

class TutorDetailResult {
  final bool success;
  final Map<String, dynamic>? tutor;
  final String? errorMessage;

  const TutorDetailResult._({
    required this.success,
    this.tutor,
    this.errorMessage,
  });

  factory TutorDetailResult.success(Map<String, dynamic> tutor) =>
      TutorDetailResult._(success: true, tutor: tutor);

  factory TutorDetailResult.error(String message) =>
      TutorDetailResult._(success: false, errorMessage: message);
}

class BookingListResult {
  final bool success;
  final List<Booking>? bookings;
  final String? errorMessage;

  const BookingListResult._({
    required this.success,
    this.bookings,
    this.errorMessage,
  });

  factory BookingListResult.success(List<Booking> bookings) =>
      BookingListResult._(success: true, bookings: bookings);

  factory BookingListResult.error(String message) =>
      BookingListResult._(success: false, errorMessage: message);
}

class JoinInfoResult {
  final bool success;
  final String? meetingUrl;
  final String? roomPassword;
  final String? errorMessage;

  const JoinInfoResult._({
    required this.success,
    this.meetingUrl,
    this.roomPassword,
    this.errorMessage,
  });

  factory JoinInfoResult.success({
    required String meetingUrl,
    String? roomPassword,
  }) =>
      JoinInfoResult._(success: true, meetingUrl: meetingUrl, roomPassword: roomPassword);

  factory JoinInfoResult.error(String message) =>
      JoinInfoResult._(success: false, errorMessage: message);
}

// ─── Chat Models ──────────────────────────────────────────────────────────────

class ChatUser {
  final String id;
  final String? fullName;
  final String? username;
  final String? avatarUrl;
  final String? status;

  const ChatUser({
    required this.id,
    this.fullName,
    this.username,
    this.avatarUrl,
    this.status,
  });

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    // Handle both snake_case and camelCase, and generic 'name' field
    final name = json['full_name']?.toString() ?? 
                 json['fullName']?.toString() ?? 
                 json['name']?.toString();
    
    return ChatUser(
      id: json['id']?.toString() ?? '',
      fullName: name,
      username: json['username']?.toString() ?? json['userName']?.toString(),
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      status: json['user_status']?.toString() ?? json['status']?.toString(),
    );
  }

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) return fullName!;
    if (username != null && username!.trim().isNotEmpty) return username!;
    return 'User ${id.length > 4 ? id.substring(0, 4) : id}';
  }
}

class ChatThread {
  final ChatUser partner;
  final ChatMessage lastMessage;
  final int unreadCount;

  const ChatThread({
    required this.partner,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) => ChatThread(
        partner: ChatUser.fromJson(
            json['partner'] is Map<String, dynamic> ? json['partner'] : {}),
        lastMessage: ChatMessage.fromJson(
            json['last_message'] is Map<String, dynamic> ? json['last_message'] : {}),
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      );
}

class ChatMessage {
  final String id;
  final String fromId;
  final String? toId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.fromId,
    this.toId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id']?.toString() ?? '',
        fromId: json['from_id']?.toString() ?? '',
        toId: json['to_id']?.toString(),
        content: json['content']?.toString() ?? '',
        isRead: json['is_read'] is bool ? json['is_read'] : false,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

// ─── Chat Result Classes ──────────────────────────────────────────────────────

class ChatThreadListResult {
  final bool success;
  final List<ChatThread>? threads;
  final String? errorMessage;

  const ChatThreadListResult._({
    required this.success,
    this.threads,
    this.errorMessage,
  });

  factory ChatThreadListResult.success(List<ChatThread> threads) =>
      ChatThreadListResult._(success: true, threads: threads);

  factory ChatThreadListResult.error(String message) =>
      ChatThreadListResult._(success: false, errorMessage: message);
}

class ChatMessageListResult {
  final bool success;
  final List<ChatMessage>? messages;
  final String? errorMessage;

  const ChatMessageListResult._({
    required this.success,
    this.messages,
    this.errorMessage,
  });

  factory ChatMessageListResult.success(List<ChatMessage> messages) =>
      ChatMessageListResult._(success: true, messages: messages);

  factory ChatMessageListResult.error(String message) =>
      ChatMessageListResult._(success: false, errorMessage: message);
}

class SendMessageResult {
  final bool success;
  final ChatMessage? message;
  final String? errorMessage;

  const SendMessageResult._({
    required this.success,
    this.message,
    this.errorMessage,
  });

  factory SendMessageResult.success(ChatMessage message) =>
      SendMessageResult._(success: true, message: message);

  factory SendMessageResult.error(String message) =>
      SendMessageResult._(success: false, errorMessage: message);
}