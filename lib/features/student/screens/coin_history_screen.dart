import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/coin_service.dart';
import '../../../core/widgets/common/api_error_snackbar.dart';

class CoinHistoryScreen extends StatefulWidget {
  const CoinHistoryScreen({super.key});

  @override
  State<CoinHistoryScreen> createState() => _CoinHistoryScreenState();
}

class _CoinHistoryScreenState extends State<CoinHistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });

    // Refresh live balance first so the coin chip on other screens stays current.
    await CoinService.instance.getCoinBalance();

    final result = await CoinService.instance.getCoinHistory();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) {
        _history = result.history ?? [];
      } else {
        _error = result.errorMessage;
        ApiErrorSnackbar.show(context, result.errorMessage ?? 'Failed to load history');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        title: const Text('Coin History', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _history.isEmpty
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
          Text(_error ?? 'Failed to load history'),
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
          Icon(Icons.toll_rounded, size: 64, color: AppColors.textTertiary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('No transactions yet', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.md),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.sm),
        itemBuilder: (context, i) => _HistoryItem(tx: _history[i]),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _HistoryItem({required this.tx});

  @override
  Widget build(BuildContext context) {
    final kind = tx['kind']?.toString() ?? 'TRANSACTION';
    final amount = (tx['amount'] as num?)?.toInt() ?? 0;
    final note = tx['note']?.toString() ?? '';
    final createdAt = DateTime.tryParse(tx['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
    
    final isPositive = amount > 0;
    final color = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(
              isPositive ? Icons.add_rounded : Icons.remove_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatKind(kind),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (note.isNotEmpty)
                  Text(
                    note,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  DateFormat('d MMM yyyy · HH:mm').format(createdAt),
                  style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}$amount',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.toll_rounded, size: 14, color: Colors.amber),
        ],
      ),
    );
  }

  String _formatKind(String kind) {
    switch (kind) {
      case 'PURCHASE': return 'Top Up';
      case 'BOOKING_PAYMENT': return 'Lesson Payment';
      case 'BOOKING_REFUND': return 'Refund';
      case 'WITHDRAWAL': return 'Withdrawal';
      case 'WELCOME_BONUS': return 'Welcome Bonus';
      default: return kind;
    }
  }
}
