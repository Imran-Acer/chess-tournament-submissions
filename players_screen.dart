import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player.dart';
import '../providers/player_provider.dart';

class PlayersScreen extends ConsumerWidget {
  const PlayersScreen({super.key});

  Future<void> _showPlayerForm(BuildContext context, WidgetRef ref, {Player? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final ratingController =
        TextEditingController(text: (existing?.rating ?? 1200).toString());
    final emailController = TextEditingController(text: existing?.email ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(existing == null ? 'Add Player' : 'Edit Player'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                autofocus: true,
              ),
              TextFormField(
                controller: ratingController,
                decoration: const InputDecoration(labelText: 'Rating (Elo)'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return int.tryParse(v) == null ? 'Must be a number' : null;
                },
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
              final rating = int.tryParse(ratingController.text.trim()) ?? 1200;
              final email = emailController.text.trim();

              if (existing == null) {
                await ref.read(playerListProvider.notifier).addPlayer(
                      name: name,
                      rating: rating,
                      email: email.isEmpty ? null : email,
                    );
              } else {
                await ref.read(playerListProvider.notifier).updatePlayer(
                      existing.copyWith(
                        name: name,
                        rating: rating,
                        email: email.isEmpty ? null : email,
                      ),
                    );
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Player player) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Player'),
        content: Text('Remove "${player.name}" from the roster? This cannot be undone.'),
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
      await ref.read(playerListProvider.notifier).deletePlayer(player.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(playerListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Players')),
      body: playersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error loading players: $err')),
        data: (players) {
          if (players.isEmpty) {
            return const Center(
              child: Text('No players yet. Tap + to add one.'),
            );
          }
          return ListView.separated(
            itemCount: players.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final player = players[index];
              return ListTile(
                leading: CircleAvatar(child: Text(player.name.isNotEmpty ? player.name[0].toUpperCase() : '?')),
                title: Text(player.name),
                subtitle: Text('Rating: ${player.rating}${player.email != null ? ' • ${player.email}' : ''}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showPlayerForm(context, ref, existing: player);
                    } else if (value == 'delete') {
                      _confirmDelete(context, ref, player);
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
        onPressed: () => _showPlayerForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
