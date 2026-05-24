import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/services/user_api_service.dart';
import '../../screens/chat_detail.screen.dart';

class StudentMessageTab extends StatefulWidget {
  const StudentMessageTab({super.key});

  @override
  State<StudentMessageTab> createState() => _StudentMessageTabState();
}

class _StudentMessageTabState extends State<StudentMessageTab> {
  List<ChatThread> _threads = [];
  List<ChatThread> _filtered = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });

    final result = await UserApiService.instance.getChatThreadList();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.success) {
        _threads = result.threads ?? [];
        _filtered = _threads;
      } else {
        _error = result.errorMessage;
      }
    });
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filtered = _threads
          .where((t) => t.partner.displayName.toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.lg, AppSizes.lg, AppSizes.lg, AppSizes.md),
            child: const Text(
              'Messages',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.sectionLabelDark,
              ),
            ),
          ),

          // ── Search ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2))
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(
                      color: AppColors.textTertiary, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: AppColors.textTertiary, size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.md),

          // ── Content ──────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : _filtered.isEmpty
                        ? const _EmptyMessages()
                        : _buildThreadList(),
          ),
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

  Widget _buildThreadList() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
            AppSizes.lg, 0, AppSizes.lg, 100),
        itemCount: _filtered.length,
        itemBuilder: (context, i) => _ThreadCard(thread: _filtered[i]),
      ),
    );
  }
}

// ─── Thread Card ──────────────────────────────────────────────────────────────

class _ThreadCard extends StatelessWidget {
  final ChatThread thread;
  const _ThreadCard({required this.thread});

  @override
  Widget build(BuildContext context) {
    final name = thread.partner.displayName;
    final trimmedName = name.trim();
    final initials = trimmedName.isEmpty
        ? '?'
        : trimmedName.split(' ').where((e) => e.isNotEmpty).map((e) => e[0]).take(2).join().toUpperCase();
    final avatarUrl = thread.partner.avatarUrl;
    final isRead = thread.unreadCount == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSizes.md, vertical: AppSizes.xs),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage:
              avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Text(initials,
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14))
              : null,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          thread.lastMessage.content,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: isRead ? AppColors.textTertiary : AppColors.textSecondary,
            fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(thread.lastMessage.createdAt),
              style: TextStyle(
                fontSize: 11,
                color: isRead ? AppColors.textTertiary : AppColors.primary,
              ),
            ),
            if (!isRead) ...[
              const SizedBox(height: 4),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
        onTap: () {
         Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              otherId: thread.partner.id,
              otherName: thread.partner.displayName,
              otherAvatarUrl: thread.partner.avatarUrl,
      ),
    ),
  );
},
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded,
                color: AppColors.primary, size: 40),
          ),
          const SizedBox(height: AppSizes.md),
          const Text(
            'No messages yet',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.sectionLabelDark),
          ),
          const SizedBox(height: AppSizes.xs),
          const Text(
            'Start a conversation with a tutor\nafter booking a session',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}