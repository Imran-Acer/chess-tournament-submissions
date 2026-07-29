import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/player.dart';
import 'database_provider.dart';

final _uuid = Uuid();


class PlayerListNotifier extends AsyncNotifier<List<Player>> {
  @override
  Future<List<Player>> build() async {
    final db = ref.read(databaseServiceProvider);
    return db.getAllPlayers();
  }

  Future<void> addPlayer({
    required String name,
    int rating = 1200,
    String? email,
  }) async {
    final db = ref.read(databaseServiceProvider);
    final player = Player(id: _uuid.v4(), name: name, rating: rating, email: email);
    await db.insertPlayer(player);
    state = AsyncValue.data(await db.getAllPlayers());
  }

  Future<void> updatePlayer(Player player) async {
    final db = ref.read(databaseServiceProvider);
    await db.updatePlayer(player);
    state = AsyncValue.data(await db.getAllPlayers());
  }

  Future<void> deletePlayer(String id) async {
    final db = ref.read(databaseServiceProvider);
    await db.deletePlayer(id);
    state = AsyncValue.data(await db.getAllPlayers());
  }
}

final playerListProvider =
    AsyncNotifierProvider<PlayerListNotifier, List<Player>>(
  PlayerListNotifier.new,
);
