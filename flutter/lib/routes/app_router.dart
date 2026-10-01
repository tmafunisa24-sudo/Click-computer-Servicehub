// lib/routes/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/design/app_colors.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/home/shell_scaffold.dart';
import '../views/home/admin_home_view.dart';
import '../views/home/technician_home_view.dart';
import '../views/home/client_home_view.dart';
import '../views/tickets/ticket_list_view.dart';
import '../views/tickets/ticket_details_view.dart';
import '../views/tickets/create_ticket_view.dart';
import '../views/notification/notifications_view.dart';
import '../views/assets/asset_list_view.dart';
import '../views/assets/asset_details_view.dart';
import '../views/profile/profile_view.dart';
import '../views/users/user_list_view.dart';
import '../views/maintenance/maintenance_list_view.dart';
import '../views/maintenance/maintenance_details_view.dart';
import '../views/departments/department_list_view.dart';
import '../views/reports/report_view.dart';

class AppRouter {
  AppRouter._();

  static GoRouter build(BuildContext context) {
    final authVm = context.read<AuthViewModel>();

    final rootNavigatorKey = GlobalKey<NavigatorState>();

    return GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: authVm,
      redirect: (context, state) {
        final isAuthenticated = authVm.isAuthenticated;
        final isBooting = authVm.state == AuthState.unknown;
        final location = state.matchedLocation;

        const publicRoutes = <String>{
          '/login',
          '/auth/register',
          '/auth/forgot-password',
        };

        final isOnSplash = location == '/splash';
        final isPublic = publicRoutes.contains(location);

        if (isBooting) {
          return isOnSplash ? null : '/splash';
        }

        if (!isAuthenticated && !isPublic) return '/login';
        if (isAuthenticated && (isPublic || isOnSplash)) return '/home';

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const _SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: '/auth/register',
          name: 'register',
          builder: (context, state) => const RegisterView(),
        ),
        GoRoute(
          path: '/auth/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordView(),
        ),

        // ── Full-screen detail routes (push OVER the shell, no bottom nav) ──
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/tickets/new',
          builder: (context, state) => const CreateTicketView(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/tickets/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return TicketDetailsView(ticketId: id);
          },
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/assets/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return AssetDetailsView(assetId: id);
          },
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/maintenance/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return MaintenanceDetailsView(recordId: id);
          },
        ),

        // ── Screens reachable via top bar / More sheet (push over shell) ──
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/profile',
          builder: (context, state) => const ProfileView(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/notifications',
          builder: (context, state) => const NotificationsView(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/users',
          builder: (context, state) => const UserListView(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/departments',
          builder: (context, state) => const DepartmentListView(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/reports',
          builder: (context, state) => const ReportView(),
        ),
        GoRoute(
          parentNavigatorKey: rootNavigatorKey,
          path: '/maintenance',
          builder: (context, state) => const MaintenanceListView(),
        ),

        // ── The 4-branch shell ──
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ShellScaffold(navigationShell: navigationShell);
          },
          branches: [
            // Branch 0 — Home
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const _RoleHome(),
                ),
              ],
            ),
            // Branch 1 — Tickets
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/tickets',
                  builder: (context, state) => const TicketListView(),
                ),
              ],
            ),
            // Branch 2 — Assets / Maintenance / New Request
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/branch2',
                  builder: (context, state) => const _RoleBranch2(),
                ),
              ],
            ),
            // Branch 3 — Admin More (never navigated) / Alerts
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/branch3',
                  builder: (context, state) => const _RoleBranch3(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────
// Role dispatchers for shell branches
// ────────────────────────────────────────────────────────

class _RoleHome extends StatelessWidget {
  const _RoleHome();

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthViewModel>().user?.role ?? '';
    if (role == 'Admin') return const AdminHomeView();
    if (role == 'Technician') return const TechnicianHomeView();
    return const ClientHomeView();
  }
}

class _RoleBranch2 extends StatelessWidget {
  const _RoleBranch2();

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthViewModel>().user?.role ?? '';
    if (role == 'Admin') return const AssetListView();
    if (role == 'Technician') return const MaintenanceListView();
    return const CreateTicketView();
  }
}

class _RoleBranch3 extends StatelessWidget {
  const _RoleBranch3();

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthViewModel>().user?.role ?? '';
    if (role == 'Admin') {
      // Never actually navigated to — the shell intercepts the tap
      // and opens the More sheet instead.
      return const SizedBox.shrink();
    }
    // Technician and Client both use Alerts
    return const NotificationsView();
  }
}

// ────────────────────────────────────────────────────────
// Splash
// ────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'ServiceHub IT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}