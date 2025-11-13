import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: DebugApp()));
}

class DebugApp extends StatelessWidget {
  const DebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Debug Ohyo Favorites')),
        body: const DebugOhyoFavorites(),
      ),
    );
  }
}

class DebugOhyoFavorites extends StatefulWidget {
  const DebugOhyoFavorites({super.key});

  @override
  State<DebugOhyoFavorites> createState() => _DebugOhyoFavoritesState();
}

class _DebugOhyoFavoritesState extends State<DebugOhyoFavorites> {
  String _debugInfo = 'Initializing...';
  bool _isFavorited = false;
  final int testOhyoId = 1; // Test with ohyo ID 1

  @override
  void initState() {
    super.initState();
    _checkDatabaseStructure();
  }

  Future<void> _checkDatabaseStructure() async {
    try {
      final client = Supabase.instance.client;

      setState(() {
        _debugInfo = 'Checking database structure...\n';
      });

      // Check columns in favorites table
      final columnsResponse = await client
          .from('information_schema.columns')
          .select('column_name, data_type, is_nullable')
          .eq('table_name', 'favorites')
          .eq('table_schema', 'public');

      setState(() {
        _debugInfo += 'Favorites table columns:\n';
        for (var col in columnsResponse) {
          _debugInfo += '- ${col['column_name']}: ${col['data_type']} (${col['is_nullable']})\n';
        }
        _debugInfo += '\nChecking user authentication...\n';
      });

      // Check user authentication
      final user = client.auth.currentUser;
      setState(() {
        _debugInfo += 'User: ${user?.email ?? 'Not logged in'}\n';
        _debugInfo += 'User ID: ${user?.id ?? 'N/A'}\n\n';
      });

      if (user != null) {
        await _testFavoriteOperations();
      }

    } catch (e) {
      setState(() {
        _debugInfo += 'Error checking database: $e\n';
      });
    }
  }

  Future<void> _testFavoriteOperations() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser!;

      setState(() {
        _debugInfo += 'Testing favorite operations...\n';
      });

      // Test 1: Check current favorite status
      try {
        final existingFavorite = await client
            .from('favorites')
            .select('id')
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', testOhyoId)
            .maybeSingle();

        setState(() {
          _debugInfo += 'Current favorite status check: ${existingFavorite != null ? 'Favorited' : 'Not favorited'}\n';
          _isFavorited = existingFavorite != null;
        });
      } catch (e) {
        setState(() {
          _debugInfo += 'Error checking favorite status: $e\n';
        });
      }

      // Test 2: Get user's favorite ohyos using the fixed method
      try {
        final userFavorites = await client
            .from('favorites')
            .select('target_id')
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo');

        setState(() {
          _debugInfo += 'User\'s favorite ohyos: ${userFavorites.map((f) => f['target_id']).toList()}\n';
        });
      } catch (e) {
        setState(() {
          _debugInfo += 'Error getting user favorites: $e\n';
        });
      }

      // Test 3: Try to toggle favorite
      setState(() {
        _debugInfo += 'Testing toggle favorite operation...\n';
      });

      await _toggleFavorite();

    } catch (e) {
      setState(() {
        _debugInfo += 'Error in favorite operations: $e\n';
      });
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      setState(() {
        _debugInfo += 'Attempting to toggle favorite...\n';
      });

      // Check if already favorited
      final existingFavorite = await client
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('target_type', 'ohyo')
          .eq('target_id', testOhyoId)
          .maybeSingle();

      if (existingFavorite != null) {
        // Unfavorite
        setState(() {
          _debugInfo += 'Found existing favorite, attempting to delete...\n';
        });

        await client
            .from('favorites')
            .delete()
            .eq('id', existingFavorite['id']);

        setState(() {
          _debugInfo += 'Successfully unfavorited!\n';
          _isFavorited = false;
        });
      } else {
        // Favorite
        setState(() {
          _debugInfo += 'No existing favorite found, attempting to create...\n';
        });

        final favoriteData = {
          'user_id': user.id,
          'target_type': 'ohyo',
          'target_id': testOhyoId,
          'created_at': DateTime.now().toIso8601String(),
        };

        setState(() {
          _debugInfo += 'Insert data: $favoriteData\n';
        });

        await client
            .from('favorites')
            .insert(favoriteData);

        setState(() {
          _debugInfo += 'Successfully favorited!\n';
          _isFavorited = true;
        });
      }
    } catch (e) {
      setState(() {
        _debugInfo += 'Error toggling favorite: $e\n';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                _debugInfo,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Test Ohyo ID: $testOhyoId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorited ? Icons.bookmark : Icons.bookmark_border,
                  color: _isFavorited ? Colors.teal : Colors.grey,
                  size: 30,
                ),
              ),
              Text(_isFavorited ? 'Favorited' : 'Not favorited', style: const TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _checkDatabaseStructure,
            child: const Text('Refresh Debug Info'),
          ),
        ],
      ),
    );
  }
}
