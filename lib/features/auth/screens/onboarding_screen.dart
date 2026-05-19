import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../widgets/onboarding/lern_logo_box.dart';
import '../widgets/onboarding/nintendo_press_button.dart';
import '../widgets/onboarding/onboarding_models.dart';
import '../widgets/onboarding/onboarding_nav_row.dart';
import '../widgets/onboarding/onboarding_page_content.dart';
import '../widgets/onboarding/outro_overlay.dart';
import '../widgets/onboarding/page_indicator_row.dart';
import '../widgets/onboarding/particle_background.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int _pageDirection = 1;

  late final AnimationController _pageCtrl;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _titleSlideT;
  late final Animation<double> _titleFade;
  late final Animation<double> _subtitleSlideT;
  late final Animation<double> _subtitleFade;

  late final AnimationController _outroCtrl;
  late final Animation<double> _outroExpand;
  late final Animation<double> _outroLogoOpacity;
  late final Animation<double> _outroLogoScale;
  late final Animation<double> _outroLine1Opacity;
  late final Animation<Offset> _outroLine1Slide;
  late final Animation<double> _outroLine2Opacity;
  late final Animation<Offset> _outroLine2Slide;
  late final Animation<double> _outroLine3Opacity;
  late final Animation<Offset> _outroLine3Slide;
  late final Animation<double> _outroCheckScale;
  late final Animation<double> _outroCheckOpacity;
  bool _outroStarted = false;

  late final AnimationController _particleCtrl;
  late final List<ParticleData> _particles;

  late final AnimationController _rippleCtrl;

  final List<OnboardingPage> _pages = const [
    OnboardingPage(
      icon: Icons.school_rounded,
      title: 'Lern',
      subtitle:
          'Find expert tutors, book a session instantly, and pay only when you learn.',
    ),
    OnboardingPage(
      icon: Icons.person_search_rounded,
      title: 'Find a Tutor.',
      subtitle:
          'Search tutor based on specific topics and learn exactly what you need.',
    ),
    OnboardingPage(
      icon: Icons.check_box_rounded,
      title: 'Choose your tutor.',
      subtitle:
          'Browse Tutor profiles, experience, and reviews to find the best match for you',
    ),
    OnboardingPage(
      icon: Icons.book,
      title: 'Learn anything.',
      subtitle: 'Keep learning no matter how hard it is',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupParticles();
    _setupPageAnim();
    _setupOutro();
    _setupRipple();
    _pageCtrl.forward(from: 0.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageCtrl.dispose();
    _outroCtrl.dispose();
    _particleCtrl.dispose();
    _rippleCtrl.dispose();
    super.dispose();
  }

  void _setupParticles() {
    final rng = Random(7);
    _particles = List.generate(
      10,
      (i) => ParticleData(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 2.0 + rng.nextDouble() * 4.0,
        speed: 0.025 + rng.nextDouble() * 0.04,
        opacity: 0.06 + rng.nextDouble() * 0.12,
        drift: (rng.nextDouble() - 0.5) * 0.4,
        phase: rng.nextDouble() * 2 * pi,
      ),
    );
    _particleCtrl = AnimationController(
      vsync: this,
      duration: AppAnimations.particleLoop,
    )..repeat();
  }

  void _setupPageAnim() {
    _pageCtrl = AnimationController(
      vsync: this,
      duration: AppAnimations.pageEntrance,
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _pageCtrl,
          curve: const Interval(0.0, 0.55, curve: NintendoBounce())),
    );
    _iconFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _pageCtrl,
          curve: const Interval(0.0, 0.25, curve: Curves.easeOut)),
    );
    _titleSlideT = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _pageCtrl,
          curve: const Interval(0.10, 0.60, curve: Curves.easeOutCubic)),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _pageCtrl,
          curve: const Interval(0.10, 0.38, curve: Curves.easeOut)),
    );
    _subtitleSlideT = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _pageCtrl,
          curve: const Interval(0.22, 0.72, curve: Curves.easeOutCubic)),
    );
    _subtitleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _pageCtrl,
          curve: const Interval(0.22, 0.52, curve: Curves.easeOut)),
    );
  }

  void _setupOutro() {
    _outroCtrl = AnimationController(
      vsync: this,
      duration: AppAnimations.outroSequence,
    );
    _outroExpand = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _outroCtrl,
          curve: const Interval(0.0, 0.40, curve: Curves.easeInOut)),
    );
    _outroLogoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _outroCtrl,
          curve: const Interval(0.38, 0.58, curve: Curves.easeOut)),
    );
    _outroLogoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _outroCtrl,
          curve: const Interval(0.36, 0.60, curve: NintendoBounce())),
    );
    _outroLine1Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _outroCtrl,
          curve: const Interval(0.54, 0.70, curve: Curves.easeOut)),
    );
    _outroLine1Slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _outroCtrl,
        curve: const Interval(0.54, 0.72, curve: Curves.easeOutBack)));
    _outroLine2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _outroCtrl,
          curve: const Interval(0.64, 0.78, curve: Curves.easeOut)),
    );
    _outroLine2Slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _outroCtrl,
        curve: const Interval(0.64, 0.80, curve: Curves.easeOutBack)));
    _outroLine3Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _outroCtrl,
          curve: const Interval(0.74, 0.88, curve: Curves.easeOut)),
    );
    _outroLine3Slide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _outroCtrl,
        curve: const Interval(0.74, 0.90, curve: Curves.easeOutBack)));
    _outroCheckScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _outroCtrl,
          curve: const Interval(0.72, 0.92, curve: NintendoBounce())),
    );
    _outroCheckOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _outroCtrl,
          curve: const Interval(0.72, 0.82, curve: Curves.easeOut)),
    );
  }

  void _setupRipple() {
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: AppAnimations.ripple,
    );
  }

  void _runPageEntrance() {
    if (!mounted) return;
    _pageCtrl.forward(from: 0.0);
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _rippleCtrl.forward(from: 0.0);
      _pageController.nextPage(
        duration: AppAnimations.pageTransition,
        curve: AppAnimations.navTransition,
      );
    } else {
      _runOutro();
    }
  }

  void _skip() => _runOutro();

  Future<void> _runOutro() async {
    if (_outroStarted || !mounted) return;
    setState(() => _outroStarted = true);
    HapticFeedback.mediumImpact();
    await _outroCtrl.forward();
    if (!mounted) return;
    await Future.delayed(AppAnimations.outroPostDelay);
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    Navigator.of(context).pushReplacementNamed('/register');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            ParticleBackground(
              controller: _particleCtrl,
              particles: _particles,
            ),
            _buildRipple(),
            SafeArea(
              child: Column(
                children: [
                  OnboardingNavRow(
                    currentPage: _currentPage,
                    totalPages: _pages.length,
                    onBack: () {
                      HapticFeedback.lightImpact();
                      _rippleCtrl.forward(from: 0.0);
                      _pageController.previousPage(
                        duration: AppAnimations.pageTransition,
                        curve: AppAnimations.navTransition,
                      );
                    },
                    onSkip: _skip,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        if (!mounted) return;
                        final dir = index > _currentPage ? 1 : -1;
                        setState(() {
                          _pageDirection = dir;
                          _currentPage = index;
                        });
                        HapticFeedback.selectionClick();
                        _runPageEntrance();
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        final isHero = index == 0;
                        if (index == _currentPage) {
                          return RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _pageCtrl,
                              builder: (_, __) => OnboardingPageContent(
                                page: page,
                                isHero: isHero,
                                iconScaleVal: _iconScale.value,
                                iconFadeVal: _iconFade.value,
                                titleSlideTVal: _titleSlideT.value,
                                titleFadeVal: _titleFade.value,
                                subtitleSlideTVal: _subtitleSlideT.value,
                                subtitleFadeVal: _subtitleFade.value,
                                pageDirection: _pageDirection,
                              ),
                            ),
                          );
                        }
                        return RepaintBoundary(
                          child: OnboardingPageContent(
                            page: page,
                            isHero: isHero,
                            iconScaleVal: 1.0,
                            iconFadeVal: 1.0,
                            titleSlideTVal: 1.0,
                            titleFadeVal: 1.0,
                            subtitleSlideTVal: 1.0,
                            subtitleFadeVal: 1.0,
                            pageDirection: _pageDirection,
                          ),
                        );
                      },
                    ),
                  ),
                  PageIndicatorRow(
                    count: _pages.length,
                    currentIndex: _currentPage,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: NintendoPressButton(
                      text: _currentPage == 0
                          ? 'Continue →'
                          : _currentPage == _pages.length - 1
                              ? 'Get Started'
                              : 'Next  →',
                      onPressed: _nextPage,
                    ),
                  ),
                ],
              ),
            ),
            RepaintBoundary(
              child: OutroOverlay(
                controller: _outroCtrl,
                expand: _outroExpand,
                logoOpacity: _outroLogoOpacity,
                logoScale: _outroLogoScale,
                line1Opacity: _outroLine1Opacity,
                line1Slide: _outroLine1Slide,
                line2Opacity: _outroLine2Opacity,
                line2Slide: _outroLine2Slide,
                line3Opacity: _outroLine3Opacity,
                line3Slide: _outroLine3Slide,
                checkScale: _outroCheckScale,
                checkOpacity: _outroCheckOpacity,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRipple() {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _rippleCtrl,
        builder: (_, __) {
          if (_rippleCtrl.value == 0.0) return const SizedBox.shrink();
          final size = MediaQuery.of(context).size;
          final op = ((1.0 - _rippleCtrl.value) * 0.03).clamp(0.0, 1.0);
          return Center(
            child: Transform.scale(
              scale: _rippleCtrl.value.clamp(0.0, 1.0),
              child: Container(
                width: size.width * 2.2,
                height: size.width * 2.2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(op),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
