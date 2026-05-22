import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/buttons/primary_button.dart';

/// Modern subscription plans screen with theme-aware styling
class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({
    super.key,
    this.teacherName,
  });

  final String? teacherName;

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  bool _isYearly = false;
  int _selectedPlan = 1; // Default to Premium

  final List<SubscriptionPlan> _plans = [
    SubscriptionPlan(
      name: 'Free',
      monthlyPrice: 0,
      yearlyPrice: 0,
      description: 'Perfect for getting started',
      features: [
        'Access to free courses',
        'Basic community support',
        'Limited live classes',
        'Basic progress tracking',
      ],
      limitations: [
        'No premium courses',
        'No certificates',
      ],
    ),
    SubscriptionPlan(
      name: 'Premium',
      monthlyPrice: 19.99,
      yearlyPrice: 199.99,
      description: 'Best for serious learners',
      features: [
        'All free features',
        'Unlimited premium courses',
        'Priority support',
        'All live classes',
        'Downloadable resources',
        'Course certificates',
        'Ad-free experience',
      ],
      isPopular: true,
    ),
    SubscriptionPlan(
      name: 'Pro',
      monthlyPrice: 39.99,
      yearlyPrice: 399.99,
      description: 'For professionals & teams',
      features: [
        'All Premium features',
        '1-on-1 tutoring sessions',
        'Personalized learning path',
        'Career guidance',
        'Project reviews',
        'Private community access',
        'Early access to new courses',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: colorScheme.onSurface,
          ),
        ),
        title: Text(
          'Choose Your Plan',
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Billing Toggle
            _buildBillingToggle(context),
            
            // Plans
            ..._plans.asMap().entries.map((entry) {
              return _buildPlanCard(context, entry.key, entry.value);
            }),
            
            const SizedBox(height: AppSizes.lg),
            
            // Continue Button
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: PrimaryButton(
                text: 'Continue',
                onPressed: () {
                  Navigator.of(context).pushNamed('/payment');
                },
              ),
            ),
            
            // Terms
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
              child: Text(
                'By subscribing, you agree to our Terms of Service and Privacy Policy. Cancel anytime.',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: AppSizes.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.primary.withAlpha(179),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            'Unlock Your Potential',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.sm),
          Text(
            'Get unlimited access to all courses and features',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.xs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                decoration: BoxDecoration(
                  color: !_isYearly ? colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  boxShadow: !_isYearly
                      ? [
                          BoxShadow(
                            color: colorScheme.shadow.withAlpha(26),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Monthly',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: !_isYearly ? FontWeight.w600 : FontWeight.w500,
                    color: !_isYearly
                        ? colorScheme.onSurface
                        : colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isYearly = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                decoration: BoxDecoration(
                  color: _isYearly ? colorScheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                  boxShadow: _isYearly
                      ? [
                          BoxShadow(
                            color: colorScheme.shadow.withAlpha(26),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Yearly',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: _isYearly ? FontWeight.w600 : FontWeight.w500,
                        color: _isYearly
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Text(
                        'Save 17%',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, int index, SubscriptionPlan plan) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSelected = _selectedPlan == index;
    final price = _isYearly ? plan.yearlyPrice : plan.monthlyPrice;

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.md, AppSizes.md, 0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: colorScheme.primary.withAlpha(26),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          if (plan.isPopular)
            Positioned(
              top: 0,
              right: AppSizes.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppSizes.radiusSm),
                  ),
                ),
                child: Text(
                  'Most Popular',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            plan.description,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${price.toStringAsFixed(0)}',
                              style: textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurface,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                _isYearly ? '/year' : '/mo',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isYearly && price > 0)
                          Text(
                            '\$${(price / 12).toStringAsFixed(2)}/mo',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSizes.md),
                
                // Features
                ...plan.features.map((feature) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.xs),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            feature,
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                // Limitations
                if (plan.limitations != null)
                  ...plan.limitations!.map((limitation) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.xs),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Text(
                              limitation,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                
                const SizedBox(height: AppSizes.md),
                
                // Select Button
                GestureDetector(
                  onTap: () => setState(() => _selectedPlan = index),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                    child: Text(
                      isSelected ? 'Selected' : 'Select Plan',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionPlan {
  final String name;
  final double monthlyPrice;
  final double yearlyPrice;
  final String description;
  final List<String> features;
  final List<String>? limitations;
  final bool isPopular;

  SubscriptionPlan({
    required this.name,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.description,
    required this.features,
    this.limitations,
    this.isPopular = false,
  });
}
