enum TournamentStatus { upcoming, ongoing, completed }

TournamentStatus statusFromString(String value) {
  return TournamentStatus.values.firstWhere(
    (e) => e.name == value,
    orElse: () => TournamentStatus.upcoming,
  );
}

class Tournament {
  final String id;
  final String name;
  final String location;
  final DateTime date;
  final TournamentStatus status;
  final int currentRound;

  Tournament({
    required this.id,
    required this.name,
    this.location = '',
    required this.date,
    this.status = TournamentStatus.upcoming,
    this.currentRound = 0,
  });

  Tournament copyWith({
    String? name,
    String? location,
    DateTime? date,
    TournamentStatus? status,
    int? currentRound,
  }) {
    return Tournament(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      date: date ?? this.date,
      status: status ?? this.status,
      currentRound: currentRound ?? this.currentRound,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'date': date.toIso8601String(),
      'status': status.name,
      'currentRound': currentRound,
    };
  }

  factory Tournament.fromMap(Map<String, dynamic> map) {
    return Tournament(
      id: map['id'] as String,
      name: map['name'] as String,
      location: map['location'] as String? ?? '',
      date: DateTime.parse(map['date'] as String),
      status: statusFromString(map['status'] as String? ?? 'upcoming'),
      currentRound: map['currentRound'] as int? ?? 0,
    );
  }
}

/// Junction entity representing a player's participation & standing
/// within a specific tournament.
class TournamentPlayer {
  final String tournamentId;
  final String playerId;
  final double points; // win = 1, draw = 0.5, loss = 0
  final int wins;
  final int losses;
  final int draws;

  TournamentPlayer({
    required this.tournamentId,
    required this.playerId,
    this.points = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
  });

  TournamentPlayer copyWith({
    double? points,
    int? wins,
    int? losses,
    int? draws,
  }) {
    return TournamentPlayer(
      tournamentId: tournamentId,
      playerId: playerId,
      points: points ?? this.points,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tournamentId': tournamentId,
      'playerId': playerId,
      'points': points,
      'wins': wins,
      'losses': losses,
      'draws': draws,
    };
  }

  factory TournamentPlayer.fromMap(Map<String, dynamic> map) {
    return TournamentPlayer(
      tournamentId: map['tournamentId'] as String,
      playerId: map['playerId'] as String,
      points: (map['points'] as num).toDouble(),
      wins: map['wins'] as int? ?? 0,
      losses: map['losses'] as int? ?? 0,
      draws: map['draws'] as int? ?? 0,
    );
  }
}
