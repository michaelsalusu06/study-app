import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';

class TeacherEarningsTab extends StatelessWidget {
  const TeacherEarningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earnings',
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withAlpha(179),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Balance',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimary.withAlpha(204),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    '\$12,450.00',
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('This Month',
                                style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onPrimary.withAlpha(179))),
                            Text('\$4,560.00',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimary,
                                )),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pending',
                                style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onPrimary.withAlpha(179))),
                            Text('\$890.00',
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimary,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Text(
              'Recent Transactions',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSizes.sm),
            ...List.generate(5, (index) => _buildTransactionItem(context, index)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isIncome = index % 2 == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isIncome
                  ? colorScheme.primaryContainer
                  : colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              size: 20,
              color: isIncome ? colorScheme.primary : colorScheme.error,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isIncome ? 'Course Purchase' : 'Withdrawal',
                  style:
                      textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  'Feb ${20 - index}, 2024',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Text(
            isIncome
                ? '+\$${(index + 1) * 25}.00'
                : '-\$${(index + 1) * 100}.00',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isIncome ? colorScheme.primary : colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
