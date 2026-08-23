import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/question_providers.dart';
import 'screens/bookmarks/bookmarks_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/study/study_screen.dart';
import 'screens/exam/exam_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/bookmarks',
        name: 'bookmarks',
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: '/study/:category',
        name: 'study',
        builder: (context, state) {
          final category = Category.values.byName(
            state.pathParameters['category']!,
          );
          return StudyScreen(category: category);
        },
      ),
      GoRoute(
        path: '/exam/:category',
        name: 'exam',
        builder: (context, state) {
          final category = Category.values.byName(
            state.pathParameters['category']!,
          );
          return ExamScreen(category: category);
        },
      ),
    ],
  );
});
