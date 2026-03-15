import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/content_list_screen.dart';
import 'screens/content_detail_screen.dart';
import 'screens/create_content_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reports_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..init(),
      child: const BrandBrainApp(),
    ),
  );
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final auth = context.read<AuthProvider>();
    if (auth.loading) return null;
    final loggedIn = auth.authenticated;
    final isLogin = state.matchedLocation == '/login';
    if (!loggedIn && !isLogin) return '/login';
    if (loggedIn && isLogin) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => _ScaffoldWithNav(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/conteudos',
          builder: (context, state) => const ContentListScreen(),
        ),
        GoRoute(
          path: '/notificacoes',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/perfil',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/conteudo/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ContentDetailScreen(
        contentId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/novo-conteudo',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CreateContentScreen(),
    ),
    GoRoute(
      path: '/relatorios',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReportsScreen(),
    ),
  ],
);

class BrandBrainApp extends StatelessWidget {
  const BrandBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.loading) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: appTheme(),
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Brand Brain',
          theme: appTheme(),
          routerConfig: _router,
        );
      },
    );
  }
}

class _ScaffoldWithNav extends StatelessWidget {
  final Widget child;
  const _ScaffoldWithNav({required this.child});

  static const _tabs = [
    (icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', path: '/'),
    (icon: Icons.article_outlined, activeIcon: Icons.article, label: 'Conteúdos', path: '/conteudos'),
    (icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alertas', path: '/notificacoes'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'Perfil', path: '/perfil'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].path) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}
