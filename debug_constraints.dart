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
        appBar: AppBar(title: const Text('Debug Database Constraints')),
        body: const DebugConstraints(),
      ),
    );
  }
}

class DebugConstraints extends StatefulWidget {
  const DebugConstraints({super.key});

  @override
  State<DebugConstraints> createState() => _DebugConstraintsState();
}

class _DebugConstraintsState extends State<DebugConstraints> {
  String _debugInfo = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _checkConstraints();
  }

  Future<void> _checkConstraints() async {
    try {
      final client = Supabase.instance.client;

      setState(() {
        _debugInfo = 'Checking database constraints...\n';
      });

      // Check constraints for likes table
      setState(() {
        _debugInfo += 'Checking likes table constraints...\n';
      });

      try {
        final likesConstraints = await client.rpc('exec_sql', params: {
          'query': '''
            SELECT conname, pg_get_constraintdef(oid) as definition
            FROM pg_constraint
            WHERE conrelid = 'likes'::regclass
            AND contype = 'c';
          '''
        }).catchError((e) {
          setState(() {
            _debugInfo += 'RPC failed, trying direct query...\n';
          });
          return [];
        });

        setState(() {
          _debugInfo += 'Likes constraints found:\n';
          if (likesConstraints is List && likesConstraints.isNotEmpty) {
            for (var constraint in likesConstraints) {
              _debugInfo += '- ${constraint['conname']}: ${constraint['definition']}\n';
            }
          } else {
            _debugInfo += 'No check constraints found or RPC not available\n';
          }
        });
      } catch (e) {
        setState(() {
          _debugInfo += 'Error checking likes constraints: $e\n';
        });
      }

      // Check constraints for favorites table
      setState(() {
        _debugInfo += 'Checking favorites table constraints...\n';
      });

      try {
        final favoritesConstraints = await client.rpc('exec_sql', params: {
          'query': '''
            SELECT conname, pg_get_constraintdef(oid) as definition
            FROM pg_constraint
            WHERE conrelid = 'favorites'::regclass
            AND contype = 'c';
          '''
        }).catchError((e) {
          return [];
        });

        setState(() {
          _debugInfo += 'Favorites constraints found:\n';
          if (favoritesConstraints is List && favoritesConstraints.isNotEmpty) {
            for (var constraint in favoritesConstraints) {
              _debugInfo += '- ${constraint['conname']}: ${constraint['definition']}\n';
            }
          } else {
            _debugInfo += 'No check constraints found or RPC not available\n';
          }
        });
      } catch (e) {
        setState(() {
          _debugInfo += 'Error checking favorites constraints: $e\n';
        });
      }

      // Try to test inserting with 'ohyo'
      setState(() {
        _debugInfo += '\nTesting insert with target_type = \'ohyo\'...\n';
      });

      try {
        await client
            .from('favorites')
            .insert({
              'user_id': 'test-user',
              'target_type': 'ohyo',
              'target_id': 1,
            });

        setState(() {
          _debugInfo += '✅ Test insert succeeded!\n';
        });

        // Clean up test data
        await client
            .from('favorites')
            .delete()
            .eq('user_id', 'test-user');

        setState(() {
          _debugInfo += '✅ Test cleanup completed\n';
        });
      } catch (e) {
        setState(() {
          _debugInfo += '❌ Test insert failed: $e\n';
        });
      }

    } catch (e) {
      setState(() {
        _debugInfo += 'Error in constraint checking: $e\n';
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
          ElevatedButton(
            onPressed: _checkConstraints,
            child: const Text('Refresh Constraints Check'),
          ),
        ],
      ),
    );
  }
}
