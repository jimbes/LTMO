import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/ltmo_colors.dart';
import '../theme/app_colors.dart';
import '../providers/data_refresh.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/sync_queue_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/agenda/agenda_screen.dart';
import '../screens/medications/treatment_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/medications/add_medication_screen.dart';
import '../screens/medications/edit_medication_screen.dart';
import '../screens/appointments/add_appointment_screen.dart';
import '../screens/appointments/edit_appointment_screen.dart';
import '../screens/appointments/post_visit_update_screen.dart';
import '../screens/appointments/all_appointments_screen.dart';
import '../screens/journey/configure_journey_screen.dart';
import '../screens/practitioners/practitioners_screen.dart';
import '../screens/settings/notifications_settings_screen.dart';
import '../screens/settings/partner_sharing_screen.dart';
import '../screens/settings/personal_info_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/agenda',
          name: 'agenda',
          builder: (context, state) => AgendaScreen(
            initialDate: state.extra as DateTime?,
          ),
        ),
        GoRoute(
          path: '/traitements',
          name: 'treatments',
          builder: (context, state) => const TreatmentListScreen(),
        ),
        GoRoute(
          path: '/profil',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    // Medication routes
    GoRoute(
      path: '/medications/add',
      name: 'add_medication',
      builder: (context, state) => const AddMedicationScreen(),
    ),
    GoRoute(
      path: '/medications/edit/:medicationId/:scheduleId',
      name: 'edit_medication',
      builder: (context, state) => EditMedicationScreen(
        medicationId: state.pathParameters['medicationId'] ?? '',
        scheduleId: state.pathParameters['scheduleId'] ?? '',
      ),
    ),
    // Appointment routes
    GoRoute(
      path: '/appointments/add',
      name: 'add_appointment',
      builder: (context, state) => const AddAppointmentScreen(),
    ),
    GoRoute(
      path: '/appointments/edit/:appointmentId',
      name: 'edit_appointment',
      builder: (context, state) => EditAppointmentScreen(
        appointmentId: state.pathParameters['appointmentId'] ?? '',
      ),
    ),
    GoRoute(
      path: '/appointments/post-visit',
      name: 'post_visit_update',
      builder: (context, state) => const PostVisitUpdateScreen(),
    ),
    // Journey routes
    GoRoute(
      path: '/journey/configure',
      name: 'configure_journey',
      builder: (context, state) => const ConfigureJourneyScreen(),
    ),
    // Practitioners routes (kept, but no longer linked from the profile
    // menu - unused in practice, replaced by the appointments list below)
    GoRoute(
      path: '/practitioners',
      name: 'practitioners',
      builder: (context, state) => const PractitionersScreen(),
    ),
    GoRoute(
      path: '/appointments/all',
      name: 'all_appointments',
      builder: (context, state) => const AllAppointmentsScreen(),
    ),
    // Settings routes
    GoRoute(
      path: '/notifications-settings',
      name: 'notifications_settings',
      builder: (context, state) => const NotificationsSettingsScreen(),
    ),
    GoRoute(
      path: '/partner-sharing',
      name: 'partner_sharing',
      builder: (context, state) => const PartnerSharingScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      name: 'edit_profile',
      builder: (context, state) => const PersonalInfoScreen(),
    ),
  ],
);

/// Lets auth_provider.dart trigger a login redirect (e.g. on a 401 session
/// expiry) without importing this file back, which would create a cycle
/// (router -> screens -> auth_provider -> router). Called once from main().
void wireAuthProviderNavigation() {
  UserNotifier.navigateToLogin = () => goRouter.go('/login');
}

class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({required this.child});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startRefreshTimer();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only poll while the app is actually visible to the user - avoids
    // wasting battery/data refreshing a backgrounded app.
    if (state == AppLifecycleState.resumed) {
      _startRefreshTimer();
      refreshAllData(ref);
    } else {
      _refreshTimer?.cancel();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshAllData(ref);
    });
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/agenda');
        break;
      case 2:
        // FAB action handled separately
        break;
      case 3:
        GoRouter.of(context).go('/traitements');
        break;
      case 4:
        GoRouter.of(context).go('/profil');
        break;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    final pendingCount = ref.watch(pendingActionsProvider).valueOrNull?.length ?? 0;

    // Sync immediately the moment connectivity comes back, instead of
    // waiting for the next 30s tick.
    ref.listen(isOnlineProvider, (previous, next) {
      if (previous == false && next == true) {
        refreshAllData(ref);
      }
    });

    // Each conflict message is shown once, then cleared from the list -
    // processQueue() only ever appends to it.
    ref.listen(conflictMessagesProvider, (previous, next) {
      if (next.isEmpty) return;
      for (final message in next) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), duration: const Duration(seconds: 5)),
        );
      }
      ref.read(conflictMessagesProvider.notifier).state = [];
    });

    return Scaffold(
      body: Column(
        children: [
          if (!isOnline)
            Container(
              width: double.infinity,
              color: AppColors.error,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: SafeArea(
                bottom: false,
                child: Text(
                  pendingCount > 0
                      ? 'Connexion perdue - $pendingCount modification${pendingCount > 1 ? 's' : ''} en attente de synchronisation'
                      : 'Connexion perdue - vos modifications seront synchronisées automatiquement',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Expanded(child: widget.child),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        height: 70,
        notchMargin: 10,
        elevation: 4,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _NavBarItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Accueil',
                isSelected: _selectedIndex == 0,
                onTap: () => _onItemTapped(0),
              ),
            ),
            Expanded(
              child: _NavBarItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                label: 'Agenda',
                isSelected: _selectedIndex == 1,
                onTap: () => _onItemTapped(1),
              ),
            ),
            const SizedBox(width: 56),
            Expanded(
              child: _NavBarItem(
                icon: Icons.medication_outlined,
                activeIcon: Icons.medication,
                label: 'Traitements',
                isSelected: _selectedIndex == 3,
                onTap: () => _onItemTapped(3),
              ),
            ),
            Expanded(
              child: _NavBarItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profil',
                isSelected: _selectedIndex == 4,
                onTap: () => _onItemTapped(4),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddActionSheet(context);
        },
        backgroundColor: LtmoColors.sauge,
        elevation: 6,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showAddActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 80,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ajouter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.medication),
              title: const Text('Médicament'),
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).push('/medications/add');
              },
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Rendez-vous'),
              onTap: () {
                Navigator.pop(context);
                GoRouter.of(context).push('/appointments/add');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? LtmoColors.sauge : const Color(0xFFB3AB9C),
            size: 22,
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 50,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? LtmoColors.sauge : const Color(0xFFB3AB9C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
