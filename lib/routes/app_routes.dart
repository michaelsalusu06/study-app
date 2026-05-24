import 'package:flutter/material.dart';
import 'package:myapp/features/auth/screens/update_profile_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/student/screens/student_dashboard.dart';
import '../features/student/screens/course_detail_screen.dart';
import '../features/student/screens/live_class_screen.dart';
import '../features/teacher/screens/teacher_dashboard.dart';
import '../features/student/screens/chat_detail.screen.dart';
import '../features/subscription/screens/subscription_plans_screen.dart';
import '../features/subscription/screens/payment_screen.dart';
import '../features/subscription/screens/payment_success_screen.dart';
import '../features/test/testWidget.dart';

/// App routes configuration
class AppRoutes {
  AppRoutes._();

  //! for test unit change this into '/' if you done comment it bro
  static const String test = '/test';

  // Route names
  // remove the splash if you done the test dude
  static const String splash = '/';
  //-------------------------------------------------

  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String roleSelection = '/role-selection';
  static const String studentDashboard = '/student-dashboard';
  static const String courseDetail = '/course-detail';
  static const String liveClass = '/live-class';
  static const String teacherDashboard = '/teacher-dashboard';
  static const String chatDetail = '/chat-detail';
  static const String subscriptionPlans = '/subscription-plans';
  static const String payment = '/payment';
  static const String paymentSuccess = '/payment-success';
  static const String UpdateProfile = "/update-profile";

  /// Generate route based on settings
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case test:
        return _buildRoute(const TestWidget() as Widget, settings);

      case UpdateProfile:
        return _buildRoute(const UpdateProfileScreen(), settings);

      case splash:
        return _buildRoute(const SplashScreen(), settings);

      case onboarding:
        return _buildRoute(const OnboardingScreen(), settings);

      case login:
        return _buildRoute(const LoginScreen(), settings);

      case register:
        return _buildRoute(const RegisterScreen(), settings);

      case roleSelection:
        return _buildRoute(const RoleSelectionScreen(), settings);

      case studentDashboard:
        return _buildRoute(const StudentDashboard(), settings);

      case courseDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          CourseDetailScreen(
            courseId: args?['courseId'] ?? '1',
          ),
          settings,
        );

      case liveClass:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          LiveClassScreen(
            classId: args?['classId'] ?? '1',
          ),
          settings,
        );

      case teacherDashboard:
        return _buildRoute(const TeacherDashboard(), settings);

      case chatDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          ChatDetailScreen(
            otherId: args?['otherId'] ?? '',
            otherName: args?['otherName'] ?? args?['userName'] ?? 'Unknown',
            otherAvatarUrl: args?['otherAvatarUrl'] ?? args?['userImage'],
          ),
          settings,
        );

      case subscriptionPlans:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          SubscriptionPlansScreen(
            teacherName: args?['teacherName'],
          ),
          settings,
        );

      case payment:
        return _buildRoute(const PaymentScreen(), settings);

      case paymentSuccess:
        return _buildRoute(const PaymentSuccessScreen(), settings);

      default:
        return _buildRoute(
          const Scaffold(
            body: Center(
              child: Text('Page not found'),
            ),
          ),
          settings,
        );
    }
  }

  /// Build a route with fade transition
  static PageRouteBuilder _buildRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
