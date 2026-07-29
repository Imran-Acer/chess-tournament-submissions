
class ChessMatch {
  final String id;
  final String tournamentId;
  final int round;
  final String player1Id;
  final String? player2Id; // null if player1 received a bye
  final String? winnerId; // null = draw (or bye winner == player1Id)
  final bool isBye;
  final DateTime playedAt;

  ChessMatch({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.player1Id,
    this.player2Id,
    this.winnerId,
    this.isBye = false,
    DateTime? playedAt,
  }) : playedAt = playedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'round': round,
      'player1Id': player1Id,
      'player2Id': player2Id,
      'winnerId': winnerId,
      'isBye': isBye ? 1 : 0,
      'playedAt': playedAt.toIso8601String(),
    };
  }

  factory ChessMatch.fromMap(Map<String, dynamic> map) {
    return ChessMatch(
      id: map['id'] as String,
      tournamentId: map['tournamentId'] as String,
      round: map['round'] as int,
      player1Id: map['player1Id'] as String,
      player2Id: map['player2Id'] as String?,
      winnerId: map['winnerId'] as String?,
      isBye: (map['isBye'] as int? ?? 0) == 1,
      playedAt: DateTime.parse(map['playedAt'] as String),
    );
  }
}
