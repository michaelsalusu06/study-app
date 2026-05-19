import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/widgets/buttons/primary_button.dart';
import '../../../data/dummy_data.dart';
import '../../../models/course_model.dart';
import '../widgets/course_detail/curriculum_tab.dart';
import '../widgets/course_detail/overview_tab.dart';
import '../widgets/course_detail/reviews_tab.dart';
import '../widgets/course_detail/teacher_tab.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CourseModel _course;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _course = DummyData.courses.firstWhere(
      (c) => c.id == widget.courseId,
      orElse: () => DummyData.courses.first,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [_buildSliverAppBar(context)],
        body: Column(
          children: [
            _buildTabBar(context),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  OverviewTab(course: _course),
                  CurriculumTab(course: _course),
                  ReviewsTab(course: _course),
                  TeacherTab(course: _course),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: Container(
          padding: const EdgeInsets.all(AppSizes.xs),
          decoration: BoxDecoration(
            color: colorScheme.surface.withAlpha(204),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_ios_new,
              size: 18, color: colorScheme.onSurface),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => setState(() => _isBookmarked = !_isBookmarked),
          icon: Container(
            padding: const EdgeInsets.all(AppSizes.xs),
            decoration: BoxDecoration(
              color: colorScheme.surface.withAlpha(204),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              size: 18,
              color:
                  _isBookmarked ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: Container(
            padding: const EdgeInsets.all(AppSizes.xs),
            decoration: BoxDecoration(
              color: colorScheme.surface.withAlpha(204),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.share_rounded,
                size: 18, color: colorScheme.onSurface),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withAlpha(77),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Icon(Icons.play_circle_outline,
                size: 64, color: colorScheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant, width: 1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle:
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
        indicatorColor: colorScheme.primary,
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Curriculum'),
          Tab(text: 'Reviews'),
          Tab(text: 'Teacher'),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.md,
        AppSizes.md,
        MediaQuery.of(context).padding.bottom + AppSizes.md,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Price',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text(
                '\$${_course.price.toStringAsFixed(0)}',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSizes.lg),
          Expanded(
            child: PrimaryButton(
              text: AppStrings.enrollNow,
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}
