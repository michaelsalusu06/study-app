import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/dummy_data.dart';
import '../../../models/live_class_model.dart';
import '../widgets/live_class/live_chat_panel.dart';
import '../widgets/live_class/live_controls_bar.dart';
import '../widgets/live_class/live_video_area.dart';
import '../widgets/live_class/pre_join_content.dart';

class LiveClassScreen extends StatefulWidget {
  const LiveClassScreen({super.key, required this.classId});

  final String classId;

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  late LiveClassModel _liveClass;
  bool _isChatVisible = false;
  bool _isJoined = false;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(name: 'Alice', message: 'Hello everyone!', isMe: false),
    ChatMessage(name: 'Bob', message: 'Hi! Excited for this class', isMe: false),
    ChatMessage(name: 'You', message: 'Hey everyone!', isMe: true),
  ];

  @override
  void initState() {
    super.initState();
    _liveClass = DummyData.liveClasses.firstWhere(
      (c) => c.id == widget.classId,
      orElse: () => DummyData.liveClasses.first,
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(
        name: 'You',
        message: _chatController.text.trim(),
        isMe: true,
      ));
      _chatController.clear();
    });
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
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _isJoined
                  ? _buildLiveContent()
                  : PreJoinContent(
                      liveClass: _liveClass,
                      onJoin: () => setState(() => _isJoined = true),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_ios_new, color: colorScheme.onSurface),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isJoined ? colorScheme.error : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      _isJoined ? 'Live Now' : 'Upcoming',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isJoined ? colorScheme.error : Colors.green,
                      ),
                    ),
                  ],
                ),
                Text(
                  _liveClass.title,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_isJoined) ...[
            IconButton(
              onPressed: () =>
                  setState(() => _isChatVisible = !_isChatVisible),
              icon: Icon(
                _isChatVisible
                    ? Icons.chat_bubble
                    : Icons.chat_bubble_outline,
                color: colorScheme.primary,
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLiveContent() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: LiveVideoArea(viewerCount: _liveClass.viewerCount),
              ),
              LiveControlsBar(
                onLeave: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        if (_isChatVisible)
          SizedBox(
            width: 300,
            child: LiveChatPanel(
              messages: _messages,
              chatController: _chatController,
              scrollController: _scrollController,
              onSend: _sendMessage,
              onClose: () => setState(() => _isChatVisible = false),
            ),
          ),
      ],
    );
  }
}
