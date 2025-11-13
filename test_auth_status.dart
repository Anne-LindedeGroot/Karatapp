import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const TestAuthApp());
}

class TestAuthApp extends StatelessWidget {
  const TestAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Auth Status Test')),
        body: const AuthStatusWidget(),
      ),
    );
  }
}

class AuthStatusWidget extends StatefulWidget {
  const AuthStatusWidget({super.key});

  @override
  State<AuthStatusWidget> createState() => _AuthStatusWidgetState();
}

class _AuthStatusWidgetState extends State<AuthStatusWidget> {
  String _authInfo = 'Checking auth status...';

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      setState(() {
        _authInfo = '''
Authentication Status:
User: ${user?.email ?? 'Not logged in'}
User ID: ${user?.id ?? 'N/A'}
Email Confirmed: ${user?.emailConfirmedAt != null ? 'Yes' : 'No'}
Last Sign In: ${user?.lastSignInAt ?? 'N/A'}
Created: ${user?.createdAt ?? 'N/A'}
User Metadata: ${user?.userMetadata ?? {}}
App Metadata: ${user?.appMetadata ?? {}}
''';
      });

      // Test a simple database query to make sure connection works
      try {
        final testQuery = await client.from('ohyo').select('id').limit(1);
        setState(() {
          _authInfo += '\nDatabase Connection: ✅ Working (${testQuery.length} records found)';
        });
      } catch (dbError) {
        setState(() {
          _authInfo += '\nDatabase Connection: ❌ Error - $dbError';
        });
      }

    } catch (e) {
      setState(() {
        _authInfo = 'Error checking auth: $e';
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      setState(() {
        _authInfo = 'Signed out successfully. Please restart the app and sign in again.';
      });
    } catch (e) {
      setState(() {
        _authInfo = 'Error signing out: $e';
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
                _authInfo,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton(
                onPressed: _checkAuthStatus,
                child: const Text('Refresh Status'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
