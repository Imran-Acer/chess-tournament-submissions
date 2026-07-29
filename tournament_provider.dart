import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/tournament.dart';
import 'database_provider.dart';

const _uuid = Uuid();

class TournamentListNotifier extends AsyncNotifier<List<Tournament>> {
  @override
  Future<List<Tournament>> build() async {
    final db = ref.read(databaseServiceProvider);
    return db.getAllTournaments();
  }

  Future<void> _refresh() async {
    final db = ref.read(databaseServiceProvider);
    state = AsyncValue.data(await db.getAllTournaments());
  }

  Future<String> addTournament({
    required String name,
    String location = '',
    required DateTime date,
  }) async {
    final db = ref.read(databaseServiceProvider);
    final tournament = Tournament(id: _uuid.v4(), name: name, location: location, date: date);
    await db.insertTournament(tournament);
    await _refresh();
    return tournament.id;
  }

  Future<void> updateTournament(Tournament tournament) async {
    final db = ref.read(databaseServiceProvider);
    await db.updateTournament(tournament);
    await _refresh();
  }

  Future<void> deleteTournament(String id) async {
    final db = ref.read(databaseServiceProvider);
    await db.deleteTournament(id);
    await _refresh();
  }
}

final tournamentListProvider =
    AsyncNotifierProvider<TournamentListNotifier, List<Tournament>>(
  TournamentListNotifier.new,
);

// Fetches a single tournament by id, re-evaluated whenever the list changes.
final tournamentByIdProvider =
    FutureProvider.family<Tournament?, String>((ref, id) async {
  ref.watch(tournamentListProvider);
  final db = ref.read(databaseServiceProvider);
  return db.getTournament(id);
});
