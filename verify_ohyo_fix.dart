import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const VerifyApp());
}

class VerifyApp extends StatelessWidget {
  const VerifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Verify Ohyo Fix')),
        body: const VerifyWidget(),
      ),
    );
  }
}

class VerifyWidget extends StatefulWidget {
  const VerifyWidget({super.key});

  @override
  State<VerifyWidget> createState() => _VerifyWidgetState();
}

class _VerifyWidgetState extends State<VerifyWidget> {
  String _status = 'Initializing verification...';
  bool _canLike = false;
  bool _canFavorite = false;

  @override
  void initState() {
    super.initState();
    _verifyDatabase();
  }

  Future<void> _verifyDatabase() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          _status = '❌ Not authenticated. Please sign in first.';
        });
        return;
      }

      setState(() {
        _status = '✅ Authenticated as: ${user.email}\n\nChecking database structure...';
      });

      // Test 1: Check table structure
      final likesColumns = await client
          .from('information_schema.columns')
          .select('column_name')
          .eq('table_name', 'likes')
          .eq('table_schema', 'public');

      final favoritesColumns = await client
          .from('information_schema.columns')
          .select('column_name')
          .eq('table_name', 'favorites')
          .eq('table_schema', 'public');

      setState(() {
        _status += '\n\nLikes table columns: ${likesColumns.map((c) => c['column_name']).join(', ')}';
        _status += '\nFavorites table columns: ${favoritesColumns.map((c) => c['column_name']).join(', ')}';
      });

      // Test 2: Try to insert test data
      setState(() {
        _status += '\n\nTesting like insertion...';
      });

      try {
        await client.from('likes').insert({
          'user_id': user.id,
          'user_name': user.userMetadata?['full_name'] ?? user.email ?? 'Test User',
          'target_type': 'ohyo',
          'target_id': 999, // Test ID that shouldn't exist
        });

        setState(() {
          _status += '\n✅ Like insertion successful!';
          _canLike = true;
        });

        // Clean up test data
        await client
            .from('likes')
            .delete()
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', 999);

      } catch (likeError) {
        setState(() {
          _status += '\n❌ Like insertion failed: $likeError';
          _canLike = false;
        });
      }

      // Test 3: Try to insert test favorite
      setState(() {
        _status += '\n\nTesting favorite insertion...';
      });

      try {
        await client.from('favorites').insert({
          'user_id': user.id,
          'target_type': 'ohyo',
          'target_id': 999, // Test ID
        });

        setState(() {
          _status += '\n✅ Favorite insertion successful!';
          _canFavorite = true;
        });

        // Clean up test data
        await client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', 999);

      } catch (favoriteError) {
        setState(() {
          _status += '\n❌ Favorite insertion failed: $favoriteError';
          _canFavorite = false;
        });
      }

      // Final status
      setState(() {
        if (_canLike && _canFavorite) {
          _status += '\n\n🎉 SUCCESS: Ohyo likes and favorites are working!';
        } else {
          _status += '\n\n❌ FAILURE: Issues remain. Check the errors above.';
        }
      });

    } catch (e) {
      setState(() {
        _status = '❌ Verification failed: $e';
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
                _status,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                _canLike ? Icons.check_circle : Icons.error,
                color: _canLike ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text('Likes: ${_canLike ? 'Working' : 'Failed'}'),
              const SizedBox(width: 20),
              Icon(
                _canFavorite ? Icons.check_circle : Icons.error,
                color: _canFavorite ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text('Favorites: ${_canFavorite ? 'Working' : 'Failed'}'),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _verifyDatabase,
            child: const Text('Run Verification Again'),
          ),
        ],
      ),
    );
  }
}
