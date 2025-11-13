import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const DebugApp());
}

class DebugApp extends StatelessWidget {
  const DebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('UUID Error Debug')),
        body: const DebugWidget(),
      ),
    );
  }
}

class DebugWidget extends StatefulWidget {
  const DebugWidget({super.key});

  @override
  State<DebugWidget> createState() => _DebugWidgetState();
}

class _DebugWidgetState extends State<DebugWidget> {
  String _debugLog = 'Starting UUID error diagnosis...\n';
  final int testOhyoId = 888888; // Unique test ID

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          _debugLog += '❌ ERROR: Not authenticated. Please sign in.\n';
        });
        return;
      }

      setState(() {
        _debugLog += '✅ Authenticated as: ${user.email}\n';
        _debugLog += 'User ID: ${user.id} (type: ${user.id.runtimeType})\n\n';
      });

      // Test 1: Check table structure
      setState(() {
        _debugLog += '🔍 Checking table structures...\n';
      });

      try {
        final likesColumns = await client
            .from('information_schema.columns')
            .select('column_name, data_type')
            .eq('table_name', 'likes')
            .eq('table_schema', 'public');

        final favoritesColumns = await client
            .from('information_schema.columns')
            .select('column_name, data_type')
            .eq('table_name', 'favorites')
            .eq('table_schema', 'public');

        setState(() {
          _debugLog += 'Likes columns:\n';
          for (var col in likesColumns) {
            _debugLog += '  - ${col['column_name']}: ${col['data_type']}\n';
          }
          _debugLog += 'Favorites columns:\n';
          for (var col in favoritesColumns) {
            _debugLog += '  - ${col['column_name']}: ${col['data_type']}\n';
          }
          _debugLog += '\n';
        });
      } catch (e) {
        setState(() {
          _debugLog += '❌ Error checking columns: $e\n\n';
        });
      }

      // Test 2: Test SELECT operations (should work)
      setState(() {
        _debugLog += '🧪 Testing SELECT operations...\n';
      });

      try {
        final likesResult = await client
            .from('likes')
            .select('*')
            .limit(1);

        final favoritesResult = await client
            .from('favorites')
            .select('*')
            .limit(1);

        setState(() {
          _debugLog += '✅ SELECT operations work\n';
          _debugLog += 'Found ${likesResult.length} likes, ${favoritesResult.length} favorites\n\n';
        });
      } catch (e) {
        setState(() {
          _debugLog += '❌ SELECT operations failed: $e\n\n';
        });
      }

      // Test 3: Test INSERT operations (this might trigger RLS)
      setState(() {
        _debugLog += '🧪 Testing INSERT operations...\n';
      });

      try {
        await client.from('likes').insert({
          'user_id': user.id,
          'user_name': user.userMetadata?['full_name'] ?? user.email ?? 'Test User',
          'target_type': 'ohyo',
          'target_id': testOhyoId,
        });

        setState(() {
          _debugLog += '✅ Likes INSERT successful\n';
        });

        // Clean up
        await client
            .from('likes')
            .delete()
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', testOhyoId);

        setState(() {
          _debugLog += '✅ Likes cleanup successful\n';
        });

      } catch (e) {
        setState(() {
          _debugLog += '❌ Likes INSERT failed: $e\n';
        });
      }

      try {
        await client.from('favorites').insert({
          'user_id': user.id,
          'target_type': 'ohyo',
          'target_id': testOhyoId,
        });

        setState(() {
          _debugLog += '✅ Favorites INSERT successful\n';
        });

        // Clean up
        await client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', testOhyoId);

        setState(() {
          _debugLog += '✅ Favorites cleanup successful\n';
        });

      } catch (e) {
        setState(() {
          _debugLog += '❌ Favorites INSERT failed: $e\n';
        });
      }

      // Test 4: Test DELETE operations (this is likely where the UUID error occurs)
      setState(() {
        _debugLog += '\n🧪 Testing DELETE operations (this triggers RLS)...\n';
      });

      // First insert test data
      try {
        await client.from('likes').insert({
          'user_id': user.id,
          'user_name': 'UUID Test User',
          'target_type': 'ohyo',
          'target_id': testOhyoId,
        });

        await client.from('favorites').insert({
          'user_id': user.id,
          'target_type': 'ohyo',
          'target_id': testOhyoId,
        });

        setState(() {
          _debugLog += '✅ Test data inserted for DELETE test\n';
        });

      } catch (e) {
        setState(() {
          _debugLog += '❌ Failed to insert test data: $e\n';
          return;
        });
      }

      // Now test DELETE (this should trigger the UUID error if policies are wrong)
      try {
        await client
            .from('likes')
            .delete()
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', testOhyoId);

        setState(() {
          _debugLog += '✅ Likes DELETE successful\n';
        });

      } catch (e) {
        setState(() {
          _debugLog += '❌ Likes DELETE failed: $e\n';
          _debugLog += 'This is likely the source of the UUID error!\n';
        });
      }

      try {
        await client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', testOhyoId);

        setState(() {
          _debugLog += '✅ Favorites DELETE successful\n';
        });

      } catch (e) {
        setState(() {
          _debugLog += '❌ Favorites DELETE failed: $e\n';
          _debugLog += 'This is likely the source of the UUID error!\n';
        });
      }

      setState(() {
        _debugLog += '\n🎯 Diagnosis complete. Check the errors above to identify the UUID issue.\n';
      });

    } catch (e) {
      setState(() {
        _debugLog += '❌ Critical error: $e\n';
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
                _debugLog,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _runDiagnostics,
            child: const Text('Run Diagnostics Again'),
          ),
        ],
      ),
    );
  }
}
