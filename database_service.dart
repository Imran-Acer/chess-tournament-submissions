import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/player.dart';
import '../models/tournament.dart';
import '../models/chess_match.dart';

/// Singleton wrapper around the sqflite database.
/// Handles schema creation/migration and exposes typed CRUD helpers
/// for Players, Tournaments, TournamentPlayers and Matches.
class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chess_tournament.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE players (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            rating INTEGER NOT NULL DEFAULT 1200,
            email TEXT,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE tournaments (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            location TEXT,
            date TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'upcoming',
            currentRound INTEGER NOT NULL DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE tournament_players (
            tournamentId TEXT NOT NULL,
            playerId TEXT NOT NULL,
            points REAL NOT NULL DEFAULT 0,
            wins INTEGER NOT NULL DEFAULT 0,
            losses INTEGER NOT NULL DEFAULT 0,
            draws INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (tournamentId, playerId),
            FOREIGN KEY (tournamentId) REFERENCES tournaments (id) ON DELETE CASCADE,
            FOREIGN KEY (playerId) REFERENCES players (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE matches (
            id TEXT PRIMARY KEY,
            tournamentId TEXT NOT NULL,
            round INTEGER NOT NULL,
            player1Id TEXT NOT NULL,
            player2Id TEXT,
            winnerId TEXT,
            isBye INTEGER NOT NULL DEFAULT 0,
            playedAt TEXT NOT NULL,
            FOREIGN KEY (tournamentId) REFERENCES tournaments (id) ON DELETE CASCADE
          )
        ''');
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // ---------------------------------------------------------------------
  // PLAYERS CRUD
  // ---------------------------------------------------------------------

  Future<void> insertPlayer(Player player) async {
    final db = await database;
    await db.insert('players', player.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Player>> getAllPlayers() async {
    final db = await database;
    final rows = await db.query('players', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map((r) => Player.fromMap(r)).toList();
  }

  Future<Player?> getPlayer(String id) async {
    final db = await database;
    final rows = await db.query('players', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Player.fromMap(rows.first);
  }

  Future<void> updatePlayer(Player player) async {
    final db = await database;
    await db.update('players', player.toMap(),
        where: 'id = ?', whereArgs: [player.id]);
  }

  Future<void> deletePlayer(String id) async {
    final db = await database;
    await db.delete('players', where: 'id = ?', whereArgs: [id]);
    await db.delete('tournament_players',
        where: 'playerId = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // TOURNAMENTS CRUD
  // ---------------------------------------------------------------------

  Future<void> insertTournament(Tournament tournament) async {
    final db = await database;
    await db.insert('tournaments', tournament.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Tournament>> getAllTournaments() async {
    final db = await database;
    final rows = await db.query('tournaments', orderBy: 'date DESC');
    return rows.map((r) => Tournament.fromMap(r)).toList();
  }

  Future<Tournament?> getTournament(String id) async {
    final db = await database;
    final rows =
        await db.query('tournaments', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Tournament.fromMap(rows.first);
  }

  Future<void> updateTournament(Tournament tournament) async {
    final db = await database;
    await db.update('tournaments', tournament.toMap(),
        where: 'id = ?', whereArgs: [tournament.id]);
  }

  Future<void> deleteTournament(String id) async {
    final db = await database;
    await db.delete('tournaments', where: 'id = ?', whereArgs: [id]);
    await db.delete('tournament_players',
        where: 'tournamentId = ?', whereArgs: [id]);
    await db.delete('matches', where: 'tournamentId = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // TOURNAMENT <-> PLAYER (registration + standings)
  // ---------------------------------------------------------------------

  Future<void> addPlayerToTournament(String tournamentId, String playerId) async {
    final db = await database;
    await db.insert(
      'tournament_players',
      TournamentPlayer(tournamentId: tournamentId, playerId: playerId).toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removePlayerFromTournament(
      String tournamentId, String playerId) async {
    final db = await database;
    await db.delete(
      'tournament_players',
      where: 'tournamentId = ? AND playerId = ?',
      whereArgs: [tournamentId, playerId],
    );
  }

  Future<List<TournamentPlayer>> getTournamentPlayers(
      String tournamentId) async {
    final db = await database;
    final rows = await db.query(
      'tournament_players',
      where: 'tournamentId = ?',
      whereArgs: [tournamentId],
    );
    return rows.map((r) => TournamentPlayer.fromMap(r)).toList();
  }

  Future<void> updateTournamentPlayerStats(TournamentPlayer tp) async {
    final db = await database;
    await db.update(
      'tournament_players',
      tp.toMap(),
      where: 'tournamentId = ? AND playerId = ?',
      whereArgs: [tp.tournamentId, tp.playerId],
    );
  }

  // ---------------------------------------------------------------------
  // MATCHES
  // ---------------------------------------------------------------------

  Future<void> insertMatch(ChessMatch match) async {
    final db = await database;
    await db.insert('matches', match.toMap());
  }

  Future<List<ChessMatch>> getMatchesForTournament(String tournamentId) async {
    final db = await database;
    final rows = await db.query(
      'matches',
      where: 'tournamentId = ?',
      whereArgs: [tournamentId],
      orderBy: 'round ASC, playedAt ASC',
    );
    return rows.map((r) => ChessMatch.fromMap(r)).toList();
  }

  Future<void> deleteAllForTesting() async {
    final db = await database;
    await db.delete('matches');
    await db.delete('tournament_players');
    await db.delete('tournaments');
    await db.delete('players');
  }
}
