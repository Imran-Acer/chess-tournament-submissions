import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/match_provider.dart';

class RankingsScreen extends ConsumerWidget {
  final String tournamentId;
  const RankingsScreen({super.key, required this.tournamentId});

  Widget _podiumSlot(BuildContext context, {
    required String place,
    required double height,
    required Color color,
    String? name,
    double? points,
  }) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            name ?? '—',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (points != null)
            Text('${points.toStringAsFixed(1)} pts', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            alignment: Alignment.center,
            child: Text(
              place,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standingsAsync = ref.watch(tournamentPlayersProvider(tournamentId));

    return standingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (standings) {
        if (standings.isEmpty) {
          return const Center(child: Text('No players registered yet.'));
        }

        final first = standings.isNotEmpty ? standings[0] : null;
        final second = standings.length > 1 ? standings[1] : null;
        final third = standings.length > 2 ? standings[2] : null;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Final Rankings', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _podiumSlot(
                  context,
                  place: '2',
                  height: 90,
                  color: Colors.blueGrey,
                  name: second?.player.name,
                  points: second?.points,
                ),
                _podiumSlot(
                  context,
                  place: '1',
                  height: 120,
                  color: Colors.amber.shade700,
                  name: first?.player.name,
                  points: first?.points,
                ),
                _podiumSlot(
                  context,
                  place: '3',
                  height: 70,
                  color: Colors.brown.shade400,
                  name: third?.player.name,
                  points: third?.points,
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Full Standings', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: standings.asMap().entries.map((entry) {
                  final rank = entry.key + 1;
                  final s = entry.value;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: rank <= 3 ? Colors.amber.withOpacity(0.2) : null,
                      child: Text('$rank'),
                    ),
                    title: Text(s.player.name),
                    subtitle: Text('W:${s.standing.wins} L:${s.standing.losses} D:${s.standing.draws}'),
                    trailing: Text(
                      '${s.points.toStringAsFixed(1)} pts',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
