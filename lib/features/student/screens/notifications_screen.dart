import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/student_profile_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _error = null; });
    
    final result = await StudentProfileService.instance.getNotifications();
    
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _notifications = List<Map<String, dynamic>>.from(result.notifications ?? []);
      } else {
        _error = result.errorMessage;
      }
    });
  }

  Future<void> _markAllSeen() async {
    final success = await StudentProfileService.instance.markAllSeen();
    if (success && mounted) {
      setState(() {
        for (var n in _notifications) {
          n['seen'] = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnseen = _notifications.any((n) => n['seen'] == false);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (hasUnseen)
            TextButton(
              onPressed: _markAllSeen,
              child: const Text('Mark all read', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _notifications.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(_error ?? 'Failed to load notifications'),
          TextButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.textTertiary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No notifications yet', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        itemCount: _notifications.length,
        itemBuilder: (context, i) => _NotificationItem(notif: _notifications[i]),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final Map<String, dynamic> notif;
  const _NotificationItem({required this.notif});

  @override
  Widget build(BuildContext context) {
    final title = notif['title']?.toString() ?? notif['type']?.toString() ?? 'Notification';
    final message = notif['message']?.toString() ?? 'You have a new update';
    final seen = notif['seen'] == true;
    final createdAtStr = notif['created_at']?.toString() ?? '';
    final createdAt = DateTime.tryParse(createdAtStr)?.toLocal() ?? DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: seen ? Colors.transparent : AppColors.primary.withOpacity(0.05),
        border: const Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicator for unseen
          if (!seen)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 12),
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
            )
          else
            const SizedBox(width: 20),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title, 
                        style: TextStyle(
                          fontWeight: seen ? FontWeight.w600 : FontWeight.w800, 
                          fontSize: 14,
                          color: seen ? AppColors.textSecondary : AppColors.textPrimary,
                        )
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(createdAt),
                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message, 
                  style: TextStyle(
                    fontSize: 13, 
                    color: seen ? AppColors.textTertiary : AppColors.textSecondary,
                    height: 1.4,
                  )
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('d MMM yyyy').format(createdAt),
                  style: const TextStyle(fontSize: 10, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
