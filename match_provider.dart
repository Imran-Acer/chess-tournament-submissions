import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/chess_match.dart';
import '../models/player.dart';
import '../models/tournament.dart';
import '../services/database_service.dart';
import 'database_provider.dart';
import 'tournament_provider.dart';

final _uuid = Uuid();
final _random = Random();

// Convenience view-model combining a Player with their standing
class TournamentStanding {
  final Player player;
  final TournamentPlayer standing;

  TournamentStanding({required this.player, required this.standing});

  double get points => standing.points;
}

// Registered players + live standings for a tournament

class TournamentPlayersNotifier
    extends FamilyAsyncNotifier<List<TournamentStanding>, String> {
  @override
  Future<List<TournamentStanding>> build(String tournamentId) async {
    return _load(tournamentId);
  }

  Future<List<TournamentStanding>> _load(String tournamentId) async {
    final db = ref.read(databaseServiceProvider);
    final tps = await db.getTournamentPlayers(tournamentId);
    final standings = <TournamentStanding>[];
    for (final tp in tps) {
      final player = await db.getPlayer(tp.playerId);
      if (player != null) {
        standings.add(TournamentStanding(player: player, standing: tp));
      }
    }
    // Rank by points desc, then wins desc, then name asc as a tiebreaker.
    standings.sort((a, b) {
      final byPoints = b.points.compareTo(a.points);
      if (byPoints != 0) return byPoints;
      final byWins = b.standing.wins.compareTo(a.standing.wins);
      if (byWins != 0) return byWins;
      return a.player.name.toLowerCase().compareTo(b.player.name.toLowerCase());
    });
    return standings;
  }

  Future<void> addPlayer(String playerId) async {
    final db = ref.read(databaseServiceProvider);
    await db.addPlayerToTournament(arg, playerId);
    state = AsyncValue.data(await _load(arg));
  }

  Future<void> removePlayer(String playerId) async {
    final db = ref.read(databaseServiceProvider);
    await db.removePlayerFromTournament(arg, playerId);
    state = AsyncValue.data(await _load(arg));
  }

  Future<void> refresh() async {
    state = AsyncValue.data(await _load(arg));
  }
}

final tournamentPlayersProvider = AsyncNotifierProvider.family<
    TournamentPlayersNotifier, List<TournamentStanding>, String>(
  TournamentPlayersNotifier.new,
);

// ---------------------------------------------------------------------
// Matches for a tournament + random round generation
// ---------------------------------------------------------------------

class TournamentMatchesNotifier
    extends FamilyAsyncNotifier<List<ChessMatch>, String> {
  @override
  Future<List<ChessMatch>> build(String tournamentId) async {
    final db = ref.read(databaseServiceProvider);
    return db.getMatchesForTournament(tournamentId);
  }

  Future<List<ChessMatch>> generateRandomRound() async {
    final db = ref.read(databaseServiceProvider);

    final tournament = await db.getTournament(arg);
    if (tournament == null) return [];

    final standingsNotifier = ref.read(tournamentPlayersProvider(arg).notifier);
    final standings = await ref.read(tournamentPlayersProvider(arg).future);

    if (standings.length < 2) {
      throw StateError('Need at least 2 players in the tournament to start a round.');
    }

    final nextRound = tournament.currentRound + 1;

    // Shuffle a copy of the player ids for random pairing.
    final ids = standings.map((s) => s.player.id).toList()..shuffle(_random);

    final createdMatches = <ChessMatch>[];

    var i = 0;
    while (i < ids.length) {
      if (i + 1 == ids.length) {
        // Odd one out gets a bye: automatic win, no opponent.
        final byePlayerId = ids[i];
        final match = ChessMatch(
          id: _uuid.v4(),
          tournamentId: arg,
          round: nextRound,
          player1Id: byePlayerId,
          player2Id: null,
          winnerId: byePlayerId,
          isBye: true,
        );
        await db.insertMatch(match);
        await _applyResult(db, winnerId: byePlayerId, loserId: null, isDraw: false);
        createdMatches.add(match);
        i += 1;
        continue;
      }

      final p1 = ids[i];
      final p2 = ids[i + 1];

      // Random outcome: ~45% p1 wins, ~45% p2 wins, ~10% draw.
      final roll = _random.nextDouble();
      String? winnerId;
      bool isDraw = false;
      if (roll < 0.45) {
        winnerId = p1;
      } else if (roll < 0.90) {
        winnerId = p2;
      } else {
        isDraw = true;
      }

      final match = ChessMatch(
        id: _uuid.v4(),
        tournamentId: arg,
        round: nextRound,
        player1Id: p1,
        player2Id: p2,
        winnerId: winnerId,
      );
      await db.insertMatch(match);

      if (isDraw) {
        await _applyDraw(db, p1, p2);
      } else {
        final loserId = winnerId == p1 ? p2 : p1;
        await _applyResult(db, winnerId: winnerId!, loserId: loserId, isDraw: false);
      }

      createdMatches.add(match);
      i += 2;
    }

    // Persist the advanced round + mark tournament as ongoing.
    final updatedTournament = tournament.copyWith(
      currentRound: nextRound,
      status: TournamentStatus.ongoing,
    );
    await ref
        .read(tournamentListProvider.notifier)
        .updateTournament(updatedTournament);

    await standingsNotifier.refresh();
    state = AsyncValue.data(await db.getMatchesForTournament(arg));

    return createdMatches;
  }

  Future<void> _applyResult(
    DatabaseService db, {
    required String winnerId,
    required String? loserId,
    required bool isDraw,
  }) async {
    final tps = await db.getTournamentPlayers(arg);
    final winnerTp = tps.firstWhere((t) => t.playerId == winnerId);
    await db.updateTournamentPlayerStats(
      winnerTp.copyWith(points: winnerTp.points + 1, wins: winnerTp.wins + 1),
    );

    if (loserId != null) {
      final loserTp = tps.firstWhere((t) => t.playerId == loserId);
      await db.updateTournamentPlayerStats(
        loserTp.copyWith(losses: loserTp.losses + 1),
      );
    }
  }

  Future<void> _applyDraw(DatabaseService db, String p1, String p2) async {
    final tps = await db.getTournamentPlayers(arg);
    final tp1 = tps.firstWhere((t) => t.playerId == p1);
    final tp2 = tps.firstWhere((t) => t.playerId == p2);
    await db.updateTournamentPlayerStats(
      tp1.copyWith(points: tp1.points + 0.5, draws: tp1.draws + 1),
    );
    await db.updateTournamentPlayerStats(
      tp2.copyWith(points: tp2.points + 0.5, draws: tp2.draws + 1),
    );
  }
}

final tournamentMatchesProvider = AsyncNotifierProvider.family<
    TournamentMatchesNotifier, List<ChessMatch>, String>(
  TournamentMatchesNotifier.new,
);
