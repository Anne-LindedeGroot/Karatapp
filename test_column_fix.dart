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
        appBar: AppBar(title: const Text('Column Type Fix Test')),
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
  String _result = 'Testing column type fix...\n';
  bool _columnsFixed = false;
  bool _operationsWork = false;

  @override
  void initState() {
    super.initState();
    _testColumnFix();
  }

  Future<void> _testColumnFix() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          _result += '❌ Not authenticated. Please sign in.\n';
        });
        return;
      }

      setState(() {
        _result += '✅ Authenticated as ${user.email}\n';
        _result += 'User ID: ${user.id} (type: ${user.id.runtimeType})\n\n';
      });

      // Check column types
      setState(() {
        _result += '🔍 Checking column types...\n';
      });

      try {
        final likesColumns = await client
            .from('information_schema.columns')
            .select('data_type')
            .eq('table_name', 'likes')
            .eq('column_name', 'user_id')
            .eq('table_schema', 'public')
            .single();

        final favoritesColumns = await client
            .from('information_schema.columns')
            .select('data_type')
            .eq('table_name', 'favorites')
            .eq('column_name', 'user_id')
            .eq('table_schema', 'public')
            .single();

        final likesType = likesColumns['data_type'];
        final favoritesType = favoritesColumns['data_type'];

        setState(() {
          _result += 'Likes user_id type: $likesType\n';
          _result += 'Favorites user_id type: $favoritesType\n\n';
        });

        if (likesType == 'text' && favoritesType == 'text') {
          _columnsFixed = true;
          setState(() {
            _result += '✅ Column types are correct (TEXT)\n\n';
          });
        } else {
          setState(() {
            _result += '❌ Column types are still UUID - fix not applied\n\n';
          });
          return;
        }

      } catch (e) {
        setState(() {
          _result += '❌ Error checking columns: $e\n\n';
        });
        return;
      }

      // Test operations
      setState(() {
        _result += '🧪 Testing database operations...\n';
      });

      const testId = 555555;
      bool insertWorked = false;
      bool deleteWorked = false;

      try {
        // Test insert
        await client.from('likes').insert({
          'user_id': user.id,
          'user_name': user.userMetadata?['full_name'] ?? user.email ?? 'Test',
          'target_type': 'ohyo',
          'target_id': testId,
        });

        await client.from('favorites').insert({
          'user_id': user.id,
          'target_type': 'ohyo',
          'target_id': testId,
        });

        setState(() {
          _result += '✅ Insert operations successful\n';
        });
        insertWorked = true;

        // Test delete (this was failing before)
        await client
            .from('likes')
            .delete()
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', testId);

        await client
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('target_type', 'ohyo')
            .eq('target_id', testId);

        setState(() {
          _result += '✅ Delete operations successful\n';
        });
        deleteWorked = true;

      } catch (e) {
        setState(() {
          _result += '❌ Operations failed: $e\n';
        });
      }

      // Final result
      if (_columnsFixed && insertWorked && deleteWorked) {
        _operationsWork = true;
        setState(() {
          _result += '\n🎉 SUCCESS! Column types fixed and operations working!\n';
          _result += 'Ohyo likes and favorites should now work in your app.\n';
        });
      } else {
        setState(() {
          _result += '\n❌ Some issues remain. Check the errors above.\n';
        });
      }

    } catch (e) {
      setState(() {
        _result += '❌ Critical error: $e\n';
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
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: [
              Icon(
                _columnsFixed ? Icons.check_circle : Icons.error,
                color: _columnsFixed ? Colors.green : Colors.red,
                size: 32,
              ),
              const Text('Columns Fixed'),
            ],
          ),
          const SizedBox(height: 10),
          Column(
            children: [
              Icon(
                _operationsWork ? Icons.check_circle : Icons.error,
                color: _operationsWork ? Colors.green : Colors.red,
                size: 32,
              ),
              const Text('Operations Working'),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _testColumnFix,
            child: const Text('Test Again'),
          ),
        ],
      ),
    );
  }
}
