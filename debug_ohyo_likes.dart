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
        appBar: AppBar(title: const Text('Debug Ohyo Likes')),
        body: const DebugOhyoLikes(),
      ),
    );
  }
}

class DebugOhyoLikes extends StatefulWidget {
  const DebugOhyoLikes({super.key});

  @override
  State<DebugOhyoLikes> createState() => _DebugOhyoLikesState();
}

class _DebugOhyoLikesState extends State<DebugOhyoLikes> {
  String _debugInfo = 'Initializing...';
  bool _isLiked = false;
  int _likeCount = 0;
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

      // Check if likes table exists
      final tablesResponse = await client.rpc('exec_sql', params: {
        'query': "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'likes'"
      }).catchError((e) {
        // If RPC fails, try direct query
        return [];
      });

      // Check columns in likes table
      final columnsResponse = await client
          .from('information_schema.columns')
          .select('column_name, data_type, is_nullable')
          .eq('table_name', 'likes')
          .eq('table_schema', 'public');

      setState(() {
        _debugInfo += 'Likes table columns:\n';
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
        await _testLikeOperations();
      }

    } catch (e) {
      setState(() {
        _debugInfo += 'Error checking database: $e\n';
      });
    }
  }

  Future<void> _testLikeOperations() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser!;

      setState(() {
        _debugInfo += 'Testing like operations...\n';
      });

      // Test 1: Check current like status
      try {
        final existingLike = await client
            .from('likes')
            .select('id')
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', testOhyoId)
            .maybeSingle();

        setState(() {
          _debugInfo += 'Current like status check: ${existingLike != null ? 'Liked' : 'Not liked'}\n';
          _isLiked = existingLike != null;
        });
      } catch (e) {
        setState(() {
          _debugInfo += 'Error checking like status: $e\n';
        });
      }

      // Test 2: Get like count
      try {
        final likes = await client
            .from('likes')
            .select('id')
            .eq('target_type', 'ohyo')
            .eq('target_id', testOhyoId);

        setState(() {
          _debugInfo += 'Like count: ${likes.length}\n';
          _likeCount = likes.length;
        });
      } catch (e) {
        setState(() {
          _debugInfo += 'Error getting like count: $e\n';
        });
      }

      // Test 3: Try to toggle like
      setState(() {
        _debugInfo += 'Testing toggle like operation...\n';
      });

      await _toggleLike();

    } catch (e) {
      setState(() {
        _debugInfo += 'Error in like operations: $e\n';
      });
    }
  }

  Future<void> _toggleLike() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      setState(() {
        _debugInfo += 'Attempting to toggle like...\n';
      });

      // Check if already liked
      final existingLike = await client
          .from('likes')
          .select('id')
          .eq('user_id', user.id)
          .eq('target_type', 'ohyo')
          .eq('target_id', testOhyoId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        setState(() {
          _debugInfo += 'Found existing like, attempting to delete...\n';
        });

        await client
            .from('likes')
            .delete()
            .eq('id', existingLike['id']);

        setState(() {
          _debugInfo += 'Successfully unliked!\n';
          _isLiked = false;
          _likeCount--;
        });
      } else {
        // Like
        setState(() {
          _debugInfo += 'No existing like found, attempting to create...\n';
        });

        final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';

        final likeData = {
          'user_id': user.id,
          'user_name': userName,
          'target_type': 'ohyo',
          'target_id': testOhyoId,
        };

        setState(() {
          _debugInfo += 'Insert data: $likeData\n';
        });

        await client
            .from('likes')
            .insert(likeData);

        setState(() {
          _debugInfo += 'Successfully liked!\n';
          _isLiked = true;
          _likeCount++;
        });
      }
    } catch (e) {
      setState(() {
        _debugInfo += 'Error toggling like: $e\n';
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
                onPressed: _toggleLike,
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.grey,
                  size: 30,
                ),
              ),
              Text('$_likeCount likes', style: const TextStyle(fontSize: 16)),
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
