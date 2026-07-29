import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';

// Provides the singleton DatabaseService instance to the rest of the app.


final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService.instance;
});
