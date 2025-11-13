import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('RLS Fix Test')),
        body: const TestWidget(),
      ),
    );
  }
}

class TestWidget extends StatefulWidget {
  const TestWidget({super.key});

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  String _status = 'Testing RLS fix...';
  bool _likesWork = false;
  bool _favoritesWork = false;
  int _existingLikes = 0;
  int _existingFavorites = 0;

  @override
  void initState() {
    super.initState();
    _testRlsFix();
  }

  Future<void> _testRlsFix() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          _status = '❌ Not authenticated. Please sign in.';
        });
        return;
      }

      setState(() {
        _status = '✅ Authenticated as ${user.email}\n\n🔍 Checking existing data...';
      });

      // Check existing data counts
      final likesData = await client.from('likes').select('id, target_type');
      final favoritesData = await client.from('favorites').select('id, target_type');

      final ohyoLikes = likesData.where((l) => l['target_type'] == 'ohyo').length;
      final kataLikes = likesData.where((l) => l['target_type'] == 'kata').length;
      final ohyoFavorites = favoritesData.where((f) => f['target_type'] == 'ohyo').length;
      final kataFavorites = favoritesData.where((f) => f['target_type'] == 'kata').length;

      setState(() {
        _existingLikes = likesData.length;
        _existingFavorites = favoritesData.length;
        _status += '\n📊 Found: ${likesData.length} total likes (${kataLikes} kata, ${ohyoLikes} ohyo)';
        _status += '\n📊 Found: ${favoritesData.length} total favorites (${kataFavorites} kata, ${ohyoFavorites} ohyo)';
        _status += '\n\n🧪 Testing ohyo operations...';
      });

      // Test ohyo like
      try {
        const testId = 777777; // Unique test ID
        await client.from('likes').insert({
          'user_id': user.id,
          'user_name': user.userMetadata?['full_name'] ?? user.email ?? 'Test',
          'target_type': 'ohyo',
          'target_id': testId,
        });

        setState(() {
          _status += '\n✅ Ohyo like insertion: SUCCESS';
          _likesWork = true;
        });

        // Clean up
        await client
            .from('likes')
            .delete()
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', testId);

      } catch (e) {
        setState(() {
          _status += '\n❌ Ohyo like insertion: FAILED\n   Error: $e';
          _likesWork = false;
        });
      }

      // Test ohyo favorite
      try {
        const testId = 777777; // Unique test ID
        await client.from('favorites').insert({
          'user_id': user.id,
          'target_type': 'ohyo',
          'target_id': testId,
        });

        setState(() {
          _status += '\n✅ Ohyo favorite insertion: SUCCESS';
          _favoritesWork = true;
        });

        // Clean up
        await client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', testId);

      } catch (e) {
        setState(() {
          _status += '\n❌ Ohyo favorite insertion: FAILED\n   Error: $e';
          _favoritesWork = false;
        });
      }

      // Final status
      if (_likesWork && _favoritesWork) {
        setState(() {
          _status += '\n\n🎉 SUCCESS! RLS fix worked!';
          _status += '\n📦 All existing data preserved: $_existingLikes likes, $_existingFavorites favorites';
        });
      } else {
        setState(() {
          _status += '\n\n❌ RLS fix incomplete. Check errors above.';
        });
      }

    } catch (e) {
      setState(() {
        _status = '❌ Test failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Icon(
                    _likesWork ? Icons.favorite : Icons.favorite_border,
                    color: _likesWork ? Colors.red : Colors.grey,
                    size: 32,
                  ),
                  Text(
                    'Likes',
                    style: TextStyle(
                      color: _likesWork ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 40),
              Column(
                children: [
                  Icon(
                    _favoritesWork ? Icons.bookmark : Icons.bookmark_border,
                    color: _favoritesWork ? Colors.teal : Colors.grey,
                    size: 32,
                  ),
                  Text(
                    'Favorites',
                    style: TextStyle(
                      color: _favoritesWork ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Existing data: $_existingLikes likes, $_existingFavorites favorites',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _testRlsFix,
            child: const Text('Test Again'),
          ),
        ],
      ),
    );
  }
}
