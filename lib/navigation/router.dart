import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../screens/home/home_screen.dart';
import '../screens/agenda/agenda_screen.dart';
import '../screens/medications/treatment_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/medications/add_medication_screen.dart';
import '../screens/appointments/add_appointment_screen.dart';
import '../screens/journey/configure_journey_screen.dart';
import '../screens/practitioners/practitioners_screen.dart';
import '../screens/settings/notifications_settings_screen.dart';
import '../screens/settings/partner_sharing_screen.dart';
import '../screens/settings/personal_info_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: true,
  routes: [
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
          builder: (context, state) => const AgendaScreen(),
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
    // Appointment routes
    GoRoute(
      path: '/appointments/add',
      name: 'add_appointment',
      builder: (context, state) => const AddAppointmentScreen(),
    ),
    // Journey routes
    GoRoute(
      path: '/journey/configure',
      name: 'configure_journey',
      builder: (context, state) => const ConfigureJourneyScreen(),
    ),
    // Practitioners routes
    GoRoute(
      path: '/practitioners',
      name: 'practitioners',
      builder: (context, state) => const PractitionersScreen(),
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

class MainScaffold extends StatefulWidget {
  final Widget child;

  const MainScaffold({required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

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
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Agenda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_outlined),
            activeIcon: Icon(Icons.medication),
            label: 'Traitements',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddActionSheet(context);
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _showAddActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
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
