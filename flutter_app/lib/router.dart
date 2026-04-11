import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Categories matching the three question banks.
enum Category {
  cat1('Categoria 1'),
  cat2('Categoria 2'),
  cat3('Categoria 3');

  const Category(this.label);
  final String label;
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const _PlaceholderScreen(title: 'Início'),
      ),
      GoRoute(
        path: '/study/:category',
        name: 'study',
        builder: (context, state) {
          final category = state.pathParameters['category']!;
          return _PlaceholderScreen(title: 'Estudo - $category');
        },
      ),
      GoRoute(
        path: '/exam/:category',
        name: 'exam',
        builder: (context, state) {
          final category = state.pathParameters['category']!;
          return _PlaceholderScreen(title: 'Exame - $category');
        },
      ),
    ],
  );
});

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}
