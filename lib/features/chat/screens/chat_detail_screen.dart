import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/common/avatar_widget.dart';

/// Modern chat detail screen with theme-aware styling
class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.userName,
    this.userImage,
  });

  final String userName;
  final String? userImage;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final bool _isTyping = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      message: 'Hi! I have a question about the course.',
      isMe: false,
      time: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ChatMessage(
      message: 'Hello! Sure, what would you like to know?',
      isMe: true,
      time: DateTime.now().subtract(const Duration(hours: 1, minutes: 55)),
    ),
    ChatMessage(
      message: 'I\'m having trouble understanding the calculus section. Can you help?',
      isMe: false,
      time: DateTime.now().subtract(const Duration(hours: 1, minutes: 50)),
    ),
    ChatMessage(
      message: 'Of course! Let me explain. Calculus is all about understanding rates of change.',
      isMe: true,
      time: DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
    ),
    ChatMessage(
      message: 'That makes sense! Thank you for the explanation.',
      isMe: false,
      time: DateTime.now().subtract(const Duration(hours: 1)),
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        message: _messageController.text.trim(),
        isMe: true,
        time: DateTime.now(),
      ));
      _messageController.clear();
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _buildMessagesList(context),
          ),
          
          // Typing indicator
          if (_isTyping) _buildTypingIndicator(context),
          
          // Input
          _buildMessageInput(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AppBar(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back_ios_new,
          color: colorScheme.onSurface,
        ),
      ),
      title: Row(
        children: [
          AvatarWidget(
            name: widget.userName,
            size: AvatarSize.small, radius: 20,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      'Online',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.videocam_rounded,
            color: colorScheme.onSurface,
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Icon(
            Icons.call_rounded,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSizes.md),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showDate = index == 0 ||
            !_isSameDay(
              _messages[index - 1].time,
              message.time,
            );

        return Column(
          children: [
            if (showDate) _buildDateDivider(context, message.time),
            _buildMessageBubble(context, message),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateDivider(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    String dateText;
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      dateText = 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      dateText = 'Yesterday';
    } else {
      dateText = '${date.day}/${date.month}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSizes.md),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: colorScheme.outlineVariant),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            child: Text(
              dateText,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Divider(color: colorScheme.outlineVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.65;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        mainAxisAlignment:
            message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isMe) ...[
            AvatarWidget(
              name: widget.userName,
              size: AvatarSize.small,
            ),
            const SizedBox(width: AppSizes.sm),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxBubbleWidth),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: message.isMe
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppSizes.radiusMd),
                  topRight: const Radius.circular(AppSizes.radiusMd),
                  bottomLeft: Radius.circular(
                    message.isMe ? AppSizes.radiusMd : AppSizes.radiusSm,
                  ),
                  bottomRight: Radius.circular(
                    message.isMe ? AppSizes.radiusSm : AppSizes.radiusMd,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: message.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: message.isMe
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    _formatTime(message.time),
                    style: textTheme.labelSmall?.copyWith(
                      color: message.isMe
                          ? colorScheme.onPrimary.withOpacity(0.7)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: AppSizes.sm),
            Icon(
              Icons.done_all_rounded,
              size: 16,
              color: colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  Widget _buildTypingIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          AvatarWidget(
            name: widget.userName,
            size: AvatarSize.small,
          ),
          const SizedBox(width: AppSizes.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'typing',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                _buildTypingDots(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDots(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.sm,
        AppSizes.md,
        MediaQuery.of(context).padding.bottom + AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          // Attachment Button
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.attach_file_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          
          // Text Input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          
          // Emoji Button
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.emoji_emotions_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          
          // Send Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _sendMessage,
              icon: Icon(
                Icons.send_rounded,
                color: colorScheme.onPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String message;
  final bool isMe;
  final DateTime time;

  ChatMessage({
    required this.message,
    required this.isMe,
    required this.time,
  });
}
