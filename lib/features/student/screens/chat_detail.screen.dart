import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/auth_state.dart';
import '../../../../core/services/user_api_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String otherId;
  final String otherName;
  final String? otherAvatarUrl;

  const ChatDetailScreen({
    super.key,
    required this.otherId,
    required this.otherName,
    this.otherAvatarUrl,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  Timer? _pollingTimer;

  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  String get _myId => AuthState.instance.userId ?? '';

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    _startPolling();
  }

  @override
  void dispose() {
    _stopPolling();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _load(initial: false);
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _load({bool initial = false}) async {
    if (initial) {
      setState(() { _isLoading = true; _error = null; });
    }

    final result = await UserApiService.instance.getChatThread(widget.otherId);
    if (!mounted) return;

    if (result.success) {
      final newMessages = result.messages ?? [];
      
      // Update only if there are changes to avoid unnecessary rebuilds and scroll jumps
      if (newMessages.length != _messages.length || 
          (newMessages.isNotEmpty && _messages.isNotEmpty && newMessages.last.id != _messages.last.id)) {
        setState(() {
          _messages = newMessages;
          _isLoading = false;
        });
        
        // Scroll to bottom only if it's the initial load or if we're already near the bottom
        if (initial || _isNearBottom()) {
          _scrollToBottom();
        }
      } else if (initial) {
        setState(() => _isLoading = false);
      }
    } else if (initial) {
      setState(() {
        _isLoading = false;
        _error = result.errorMessage;
      });
    }
  }

  bool _isNearBottom() {
    if (!_scrollController.hasClients) return true;
    final pos = _scrollController.position;
    return pos.maxScrollExtent - pos.pixels < 100;
  }

  Future<void> _send() async {
    final content = _inputController.text.trim();
    if (content.isEmpty || _isSending) return;

    _inputController.clear();
    // No longer setting _isSending to true globally to allow optimistic UI to feel faster
    // but we can track it locally if we want to show a spinner on the send button
    
    // Optimistic UI
    final optimistic = ChatMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      fromId: _myId,
      toId: widget.otherId,
      content: content,
      isRead: false,
      createdAt: DateTime.now(),
    );
    
    setState(() {
      _messages.add(optimistic);
    });
    _scrollToBottom();

    final result = await UserApiService.instance.sendMessage(
      toId: widget.otherId,
      content: content,
    );

    if (!mounted) return;

    if (result.success) {
      // The next poll will likely bring the real message, 
      // but we can replace it now for immediate feedback
      final idx = _messages.indexWhere((m) => m.id == optimistic.id);
      if (idx != -1 && result.message != null) {
        setState(() => _messages[idx] = result.message!);
      }
    } else {
      // Remove optimistic message if failed
      setState(() => _messages.removeWhere((m) => m.id == optimistic.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Failed to send message'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trimmedName = widget.otherName.trim();
    final initials = trimmedName.isEmpty
        ? '?'
        : trimmedName.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: widget.otherAvatarUrl != null &&
                      widget.otherAvatarUrl!.isNotEmpty
                  ? NetworkImage(widget.otherAvatarUrl!)
                  : null,
              child: widget.otherAvatarUrl == null || widget.otherAvatarUrl!.isEmpty
                  ? Text(initials,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700))
                  : null,
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                widget.otherName,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages ───────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _messages.isEmpty
                        ? _buildEmpty()
                        : _buildMessageList(),
          ),

          // ── Input ──────────────────────────────────────
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: AppSizes.md),
          Text(_error!,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSizes.md),
          TextButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: AppSizes.md),
          const Text('No messages yet',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sectionLabelDark)),
          const SizedBox(height: AppSizes.xs),
          const Text('Say hello!',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
          AppSizes.lg, AppSizes.md, AppSizes.lg, AppSizes.md),
      itemCount: _messages.length,
      itemBuilder: (context, i) {
        final msg = _messages[i];
        final isMe = msg.fromId == _myId;
        final showDate = i == 0 ||
            !_sameDay(_messages[i - 1].createdAt, msg.createdAt);

        return Column(
          children: [
            if (showDate) _buildDateDivider(msg.createdAt),
            _MessageBubble(message: msg, isMe: isMe),
          ],
        );
      },
    );
  }

  Widget _buildDateDivider(DateTime dt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
            child: Text(
              _formatDate(dt),
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textTertiary),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.sm,
        AppSizes.md,
        MediaQuery.of(context).padding.bottom + AppSizes.sm,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FB),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: TextField(
                controller: _inputController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle:
                      TextStyle(color: AppColors.textTertiary, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSizes.md, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          GestureDetector(
            onTap: _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isSending
                    ? AppColors.primary.withOpacity(0.5)
                    : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (_sameDay(dt, now)) return 'Today';
    if (_sameDay(dt, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

// ─── Message Bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final time =
        '${message.createdAt.hour.toString().padLeft(2, '0')}:${message.createdAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isMe ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : AppColors.textTertiary,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 12,
                    color: message.isRead
                        ? Colors.white
                        : Colors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}