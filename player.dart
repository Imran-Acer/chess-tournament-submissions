class Player {
  final String id;
  final String name;
  final int rating;
  final String? email;
  final DateTime createdAt;

  Player({
    required this.id,
    required this.name,
    this.rating = 1200,
    this.email,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Player copyWith({
    String? name,
    int? rating,
    String? email,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      rating: rating ?? this.rating,
      email: email ?? this.email,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'email': email,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      name: map['name'] as String,
      rating: map['rating'] as int? ?? 1200,
      email: map['email'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
