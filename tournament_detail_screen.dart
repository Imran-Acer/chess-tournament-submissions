import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/match_provider.dart';
import '../providers/player_provider.dart';
import '../providers/tournament_provider.dart';
import 'rankings_screen.dart';

class TournamentDetailScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends ConsumerState<TournamentDetailScreen> {
  Future<void> _addPlayersDialog() async {
    final allPlayersAsync = ref.read(playerListProvider);
    final registered = await ref.read(tournamentPlayersProvider(widget.tournamentId).future);
    final registeredIds = registered.map((s) => s.player.id).toSet();

    final allPlayers = allPlayersAsync.value ?? [];
    final available = allPlayers.where((p) => !registeredIds.contains(p.id)).toList();

    if (available.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All players are already registered, or you have no players yet.')),
        );
      }
      return;
    }

    final selected = <String>{};

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Players to Tournament'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: available.map((p) {
                final checked = selected.contains(p.id);
                return CheckboxListTile(
                  value: checked,
                  title: Text(p.name),
                  subtitle: Text('Rating: ${p.rating}'),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        selected.add(p.id);
                      } else {
                        selected.remove(p.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final notifier = ref.read(tournamentPlayersProvider(widget.tournamentId).notifier);
                for (final id in selected) {
                  await notifier.addPlayer(id);
                }
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateRound() async {
    try {
      final matches = await ref
          .read(tournamentMatchesProvider(widget.tournamentId).notifier)
          .generateRandomRound();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated ${matches.length} match(es) for the new round.')),
      );
    } on StateError catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournamentAsync = ref.watch(tournamentByIdProvider(widget.tournamentId));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: tournamentAsync.when(
            data: (t) => Text(t?.name ?? 'Tournament'),
            loading: () => const Text('Tournament'),
            error: (_, __) => const Text('Tournament'),
          ),
          bottom: const TabBar(tabs: [
            Tab(text: 'Players', icon: Icon(Icons.people)),
            Tab(text: 'Matches', icon: Icon(Icons.sports_esports)),
            Tab(text: 'Rankings', icon: Icon(Icons.leaderboard)),
          ]),
        ),
        body: TabBarView(
          children: [
            _PlayersTab(tournamentId: widget.tournamentId, onAddPressed: _addPlayersDialog),
            _MatchesTab(tournamentId: widget.tournamentId, onGenerateRound: _generateRound),
            RankingsScreen(tournamentId: widget.tournamentId),
          ],
        ),
      ),
    );
  }
}

class _PlayersTab extends ConsumerWidget {
  final String tournamentId;
  final VoidCallback onAddPressed;
  const _PlayersTab({required this.tournamentId, required this.onAddPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(tournamentPlayersProvider(tournamentId));

    return Scaffold(
      body: standingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (standings) {
          if (standings.isEmpty) {
            return const Center(child: Text('No players registered yet. Tap + to add players.'));
          }
          return ListView.separated(
            itemCount: standings.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final s = standings[index];
              return ListTile(
                leading: CircleAvatar(child: Text(s.player.name.isNotEmpty ? s.player.name[0].toUpperCase() : '?')),
                title: Text(s.player.name),
                subtitle: Text(
                  'Pts: ${s.points} • W:${s.standing.wins} L:${s.standing.losses} D:${s.standing.draws}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Remove from tournament',
                  onPressed: () => ref
                      .read(tournamentPlayersProvider(tournamentId).notifier)
                      .removePlayer(s.player.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onAddPressed,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MatchesTab extends ConsumerWidget {
  final String tournamentId;
  final VoidCallback onGenerateRound;
  const _MatchesTab({required this.tournamentId, required this.onGenerateRound});

  String _playerName(WidgetRef ref, String? playerId) {
    if (playerId == null) return 'BYE';
    final players = ref.read(playerListProvider).value ?? [];
    for (final p in players) {
      if (p.id == playerId) return p.name;
    }
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(tournamentMatchesProvider(tournamentId));

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: FilledButton.icon(
              onPressed: onGenerateRound,
              icon: const Icon(Icons.casino),
              label: const Text('Generate Random Round'),
            ),
          ),
          Expanded(
            child: matchesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('Error: $e')),
              data: (matches) {
                if (matches.isEmpty) {
                  return const Center(
                    child: Text('No matches yet. Generate a round to get started.'),
                  );
                }

                // Group by round, most recent first.
                final rounds = matches.map((m) => m.round).toSet().toList()
                  ..sort((a, b) => b.compareTo(a));

                return ListView.builder(
                  itemCount: rounds.length,
                  itemBuilder: (context, i) {
                    final round = rounds[i];
                    final roundMatches = matches.where((m) => m.round == round).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text('Round $round', style: Theme.of(context).textTheme.titleMedium),
                        ),
                        ...roundMatches.map((m) {
                          final p1 = _playerName(ref, m.player1Id);
                          final p2 = _playerName(ref, m.player2Id);
                          String result;
                          if (m.isBye) {
                            result = '$p1 receives a bye (auto win)';
                          } else if (m.winnerId == null) {
                            result = '$p1 vs $p2 — Draw';
                          } else {
                            final winnerName = m.winnerId == m.player1Id ? p1 : p2;
                            result = '$p1 vs $p2 — Winner: $winnerName';
                          }
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.sports_esports_outlined),
                            title: Text(result),
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
