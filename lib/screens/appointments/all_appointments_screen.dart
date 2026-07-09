import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../providers/appointment_provider.dart';
import '../../models/appointment.dart';
import '../../widgets/appointment_form.dart' show appointmentTypeLabels;

/// All of the couple's appointments, grouped by type (échographie, prise de
/// sang, consultation...) - replaces the old "Mes praticiens & cliniques"
/// menu entry, which tracked practitioner contact info nobody was actually
/// using; what people actually want here is to see and manage the meetings
/// themselves.
class AllAppointmentsScreen extends ConsumerWidget {
  const AllAppointmentsScreen({super.key});

  String _typeLabel(String? type) {
    return appointmentTypeLabels[type] ?? 'Autre';
  }

  void _showEditDeleteSheet(
    BuildContext context,
    WidgetRef ref,
    Appointment appointment,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 80,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(appointment.title, style: AppTypography.titleLarge),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Modifier'),
                onTap: () {
                  Navigator.pop(context);
                  GoRouter.of(context)
                      .push('/appointments/edit/${appointment.id}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Dupliquer'),
                onTap: () async {
                  Navigator.pop(context);
                  final goRouter = GoRouter.of(context);
                  try {
                    final duplicate = await ref
                        .read(appointmentProvider.notifier)
                        .addAppointment(appointment.copyWith(completed: false));
                    if (context.mounted) {
                      goRouter.push('/appointments/edit/${duplicate.id}');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await ref
                        .read(appointmentProvider.notifier)
                        .deleteAppointment(appointment.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rendez-vous supprimé'),
                          duration: Duration(milliseconds: 1500),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentsAsync = ref.watch(appointmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes rendez-vous'),
        elevation: 0,
      ),
      body: appointmentsAsync.when(
        data: (appointments) {
          if (appointments.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Aucun rendez-vous pour le moment.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.inkTertiary),
                ),
              ),
            );
          }

          // Group by type, each group sorted most-recent-first.
          final byType = <String, List<Appointment>>{};
          for (final apt in appointments) {
            byType.putIfAbsent(_typeLabel(apt.type), () => []).add(apt);
          }
          for (final list in byType.values) {
            list.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
          }

          // Stable section order matching the type picker, with "Autre"
          // last regardless of what's actually present.
          final orderedLabels = [
            ...appointmentTypeLabels.values,
            'Autre',
          ].where(byType.containsKey).toList();

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).viewPadding.bottom,
            ),
            itemCount: orderedLabels.length,
            itemBuilder: (context, sectionIndex) {
              final label = orderedLabels[sectionIndex];
              final items = byType[label]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (sectionIndex > 0) const SizedBox(height: 24),
                  Text(
                    '$label (${items.length})',
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  ...items.map((apt) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () =>
                              _showEditDeleteSheet(context, ref, apt),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border1),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        apt.title,
                                        style: AppTypography.bodyMedium
                                            .copyWith(
                                          decoration: apt.completed
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: apt.completed
                                              ? AppColors.inkTertiary
                                              : AppColors.ink,
                                        ),
                                      ),
                                      if (apt.location != null)
                                        Text(
                                          apt.location!,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                            color: AppColors.inkTertiary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  DateFormat('d MMM yyyy', 'fr_FR')
                                      .format(apt.appointmentDate),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.inkTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }
}
