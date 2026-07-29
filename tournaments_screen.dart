import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/tournament.dart';
import '../providers/tournament_provider.dart';
import 'tournament_detail_screen.dart';

class TournamentsScreen extends ConsumerWidget {
  const TournamentsScreen({super.key});

  Future<void> _showTournamentForm(BuildContext context, WidgetRef ref, {Tournament? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final locationController = TextEditingController(text: existing?.location ?? '');
    DateTime selectedDate = existing?.date ?? DateTime.now();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'New Tournament' : 'Edit Tournament'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tournament Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  autofocus: true,
                ),
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text('Date: ${DateFormat.yMMMd().format(selectedDate)}')),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final name = nameController.text.trim();
                final location = locationController.text.trim();

                if (existing == null) {
                  await ref.read(tournamentListProvider.notifier).addTournament(
                        name: name,
                        location: location,
                        date: selectedDate,
                      );
                } else {
                  await ref.read(tournamentListProvider.notifier).updateTournament(
                        existing.copyWith(name: name, location: location, date: selectedDate),
                      );
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Tournament tournament) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Tournament'),
        content: Text('Delete "${tournament.name}" and all its matches/standings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(tournamentListProvider.notifier).deleteTournament(tournament.id);
    }
  }

  Color _statusColor(TournamentStatus status) {
    switch (status) {
      case TournamentStatus.upcoming:
        return Colors.blueGrey;
      case TournamentStatus.ongoing:
        return Colors.orange;
      case TournamentStatus.completed:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournamentsAsync = ref.watch(tournamentListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tournaments')),
      body: tournamentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading tournaments: $err')),
        data: (tournaments) {
          if (tournaments.isEmpty) {
            return const Center(
              child: Text('No tournaments yet. Tap + to create one.'),
            );
          }
          return ListView.separated(
            itemCount: tournaments.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final t = tournaments[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _statusColor(t.status).withOpacity(0.15),
                  child: Icon(Icons.emoji_events, color: _statusColor(t.status)),
                ),
                title: Text(t.name),
                subtitle: Text(
                  '${DateFormat.yMMMd().format(t.date)}'
                  '${t.location.isNotEmpty ? ' • ${t.location}' : ''}'
                  ' • ${t.status.name} • Round ${t.currentRound}',
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: t.id)),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showTournamentForm(context, ref, existing: t);
                    } else if (value == 'delete') {
                      _confirmDelete(context, ref, t);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTournamentForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
