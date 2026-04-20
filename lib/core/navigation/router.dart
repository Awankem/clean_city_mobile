import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/reporting/presentation/pages/home_page.dart';
import '../../features/reporting/presentation/pages/submit_report_page.dart';
import '../../features/map/presentation/pages/map_page.dart';
import '../../features/reporting/presentation/pages/report_history_page.dart';
import '../../features/reporting/presentation/pages/report_detail_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/home/presentation/pages/main_scaffold.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';

// Navigation keys
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    routes: [
      // ── Public / Auth routes ────────────────────────────────────────────
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // ── Authenticated Shell with persistent Bottom Nav ───────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/tracking',
            builder: (context, state) => const MapPage(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) {
              // Extract query parameter to decide which tab to show
              final cityFeed = state.uri.queryParameters['feed'] == 'true';
              return ReportHistoryPage(showCityFeed: cityFeed);
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),

      // ── Fullscreen routes (no bottom nav) ────────────────────────────
      GoRoute(
        path: '/submit-report',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SubmitReportPage(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: '/report-detail/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return ReportDetailPage(reportId: id);
        },
      ),
    ],
  );
}
