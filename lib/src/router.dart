import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'account_page.dart';
import 'discover_page.dart';
import 'home_page.dart';
import 'practice_page.dart';
import 'session.dart';
import 'widgets.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider).asData?.value;
      final path = state.uri.path;
      final guestOnly = path == '/sign-in' || path == '/join';
      final patientPath = path.startsWith('/appointments') || path == '/profile' || path == '/notifications';
      final practicePath = path.startsWith('/practice');
      if (session == null && (patientPath || practicePath)) return '/sign-in';
      if (session != null && session.isPractitioner && patientPath) return '/practice/appointments';
      if (session != null && session.isPatient && !session.isPractitioner && practicePath) return '/appointments';
      if (session != null && guestOnly) return session.isPractitioner ? '/practice/profile' : '/';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          final session = ref.watch(sessionProvider).asData?.value;
          return VaidyaShell(
            signedIn: session != null,
            practitioner: session?.isPractitioner ?? false,
            dark: state.uri.path.startsWith('/practice/availability'),
            onSignOut: () => ref.read(sessionProvider.notifier).signOut(),
            child: child,
          );
        },
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomePage()),
          GoRoute(path: '/therapies', builder: (_, __) => const TherapiesPage()),
          GoRoute(path: '/practitioners', builder: (_, __) => const PractitionersPage()),
          GoRoute(
            path: '/practitioners/:id',
            builder: (_, state) => PractitionerDetailPage(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/sign-in',
            builder: (_, state) => SignInPage(role: state.uri.queryParameters['role'] == 'Practitioner' ? 'Practitioner' : 'Patient'),
          ),
          GoRoute(path: '/join', builder: (_, __) => const PractitionerIntroPage()),
          GoRoute(path: '/appointments', builder: (_, __) => const AppointmentsPage()),
          GoRoute(
            path: '/appointments/:id',
            builder: (_, state) => AppointmentDetailPage(id: state.pathParameters['id']!),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const PatientProfilePage()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsPage()),
          GoRoute(path: '/practice/profile', builder: (_, __) => const PracticeProfilePage()),
          GoRoute(path: '/practice/availability', builder: (_, __) => const AvailabilityPage()),
          GoRoute(path: '/practice/appointments', builder: (_, __) => const PracticeAppointmentsPage()),
          GoRoute(
            path: '/practice/appointments/:id/note',
            builder: (_, state) => NotePage(id: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
});
