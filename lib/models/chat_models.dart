// Chat models extracted from user_api_service.dart.
// Import this file (or user_api_service.dart which re-exports it) wherever
// ChatUser, ChatThread, or ChatMessage is needed.

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
