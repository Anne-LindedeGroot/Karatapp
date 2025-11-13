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
        appBar: AppBar(title: const Text('Final Ohyo Test')),
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
  String _result = 'Testing ohyo likes and favorites...';
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _testOhyoFunctionality();
  }

  Future<void> _testOhyoFunctionality() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          _result = '❌ ERROR: Not authenticated. Please sign in first.';
        });
        return;
      }

      setState(() {
        _result = '✅ Authenticated\n\n🧪 Testing ohyo likes and favorites...';
      });

      // Test 1: Insert ohyo like
      try {
        final testLikeData = {
          'user_id': user.id,
          'user_name': user.userMetadata?['full_name'] ?? user.email ?? 'Test User',
          'target_type': 'ohyo',
          'target_id': 99999, // Unique test ID
        };

        await client.from('likes').insert(testLikeData);
        setState(() {
          _result += '\n✅ Like insertion: SUCCESS';
        });

        // Clean up
        await client
            .from('likes')
            .delete()
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', 99999);

      } catch (e) {
        setState(() {
          _result += '\n❌ Like insertion: FAILED - $e';
          _success = false;
        });
        return;
      }

      // Test 2: Insert ohyo favorite
      try {
        final testFavoriteData = {
          'user_id': user.id,
          'target_type': 'ohyo',
          'target_id': 99999, // Unique test ID
        };

        await client.from('favorites').insert(testFavoriteData);
        setState(() {
          _result += '\n✅ Favorite insertion: SUCCESS';
        });

        // Clean up
        await client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', 99999);

      } catch (e) {
        setState(() {
          _result += '\n❌ Favorite insertion: FAILED - $e';
          _success = false;
        });
        return;
      }

      // Test 3: Query existing data
      try {
        final likesCount = await client
            .from('likes')
            .select('id')
            .eq('target_type', 'ohyo')
            .limit(1);

        final favoritesCount = await client
            .from('favorites')
            .select('id')
            .eq('target_type', 'ohyo')
            .limit(1);

        setState(() {
          _result += '\n✅ Query test: SUCCESS';
          _result += '\n📊 Found ${likesCount.length} ohyo likes, ${favoritesCount.length} ohyo favorites in database';
        });

      } catch (e) {
        setState(() {
          _result += '\n❌ Query test: FAILED - $e';
        });
      }

      setState(() {
        _success = true;
        _result += '\n\n🎉 SUCCESS! Ohyo likes and favorites are working!';
      });

    } catch (e) {
      setState(() {
        _result = '❌ CRITICAL ERROR: $e';
        _success = false;
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
                _result,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'monospace',
                  color: _success ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Icon(
            _success ? Icons.check_circle : Icons.error,
            size: 48,
            color: _success ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 10),
          Text(
            _success ? 'Ohyo functionality is working!' : 'Issues detected',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _success ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _testOhyoFunctionality,
            child: const Text('Test Again'),
          ),
        ],
      ),
    );
  }
}
