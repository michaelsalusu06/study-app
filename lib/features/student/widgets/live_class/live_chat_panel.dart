import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/common/avatar_widget.dart';

class ChatMessage {
  final String name;
  final String message;
  final bool isMe;

  const ChatMessage({
    required this.name,
    required this.message,
    required this.isMe,
  });
}

class LiveChatPanel extends StatelessWidget {
  const LiveChatPanel({
    super.key,
    required this.messages,
    required this.chatController,
    required this.scrollController,
    required this.onSend,
    required this.onClose,
  });

  final List<ChatMessage> messages;
  final TextEditingController chatController;
  final ScrollController scrollController;
  final VoidCallback onSend;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(left: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline,
                    size: 20, color: colorScheme.onSurface),
                const SizedBox(width: AppSizes.sm),
                Text('Live Chat',
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(Icons.close,
                      size: 20, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(AppSizes.sm),
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _buildMessage(context, messages[index]),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              border:
                  Border(top: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: chatController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusFull),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md, vertical: AppSizes.sm),
                      isDense: true,
                    ),
                    onSubmitted: (_) => onSend(),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                IconButton(
                  onPressed: onSend,
                  icon: Icon(Icons.send_rounded, color: colorScheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(BuildContext context, ChatMessage message) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isMe) ...[
            AvatarWidget(name: message.name, size: AvatarSize.small),
            const SizedBox(width: AppSizes.sm),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md, vertical: AppSizes.sm),
              decoration: BoxDecoration(
                color: message.isMe
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.name,
                    style: textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: message.isMe
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(message.message, style: textTheme.bodySmall),
                ],
              ),
            ),
          ),
          if (message.isMe) ...[
            const SizedBox(width: AppSizes.sm),
            AvatarWidget(name: message.name, size: AvatarSize.small),
          ],
        ],
      ),
    );
  }
}
