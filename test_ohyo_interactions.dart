import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_client.dart';
import 'models/ohyo_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: TestApp()));
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Test Ohyo Interactions')),
        body: const TestOhyoInteractions(),
      ),
    );
  }
}

class TestOhyoInteractions extends ConsumerStatefulWidget {
  const TestOhyoInteractions({super.key});

  @override
  ConsumerState<TestOhyoInteractions> createState() => _TestOhyoInteractionsState();
}

class _TestOhyoInteractionsState extends ConsumerState<TestOhyoInteractions> {
  String _status = 'Testing ohyo interactions...';
  bool _isLiked = false;
  bool _isFavorited = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _testInteractions();
  }

  Future<void> _testInteractions() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        setState(() {
          _status = 'No user logged in. Please log in first.';
        });
        return;
      }

      // Test with a sample ohyo ID (assuming ID 1 exists)
      const int testOhyoId = 1;

      setState(() {
        _status = 'Testing database queries...';
      });

      // Test getting likes
      final likesResponse = await client
          .from('likes')
          .select('*')
          .eq('target_type', 'ohyo')
          .eq('target_id', testOhyoId);

      // Test getting favorites
      final favoritesResponse = await client
          .from('favorites')
          .select('*')
          .eq('target_type', 'ohyo')
          .eq('target_id', testOhyoId);

      // Test if current user liked/favorited
      final userLike = await client
          .from('likes')
          .select('id')
          .eq('user_id', user.id)
          .eq('target_type', 'ohyo')
          .eq('target_id', testOhyoId)
          .maybeSingle();

      final userFavorite = await client
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('target_type', 'ohyo')
          .eq('target_id', testOhyoId)
          .maybeSingle();

      setState(() {
        _status = 'Database queries successful!\n'
            'Likes: ${likesResponse.length}\n'
            'Favorites: ${favoritesResponse.length}\n'
            'User liked: ${userLike != null}\n'
            'User favorited: ${userFavorite != null}';
        _isLiked = userLike != null;
        _isFavorited = userFavorite != null;
        _likeCount = likesResponse.length;
      });

    } catch (e) {
      setState(() {
        _status = 'Error testing interactions: $e';
      });
    }
  }

  Future<void> _toggleLike() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      const int testOhyoId = 1;

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
        await client
            .from('likes')
            .delete()
            .eq('id', existingLike['id']);
        setState(() {
          _isLiked = false;
          _likeCount--;
          _status += '\nUnliked successfully!';
        });
      } else {
        // Like
        final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';
        await client
            .from('likes')
            .insert({
              'user_id': user.id,
              'user_name': userName,
              'target_type': 'ohyo',
              'target_id': testOhyoId,
            });
        setState(() {
          _isLiked = true;
          _likeCount++;
          _status += '\nLiked successfully!';
        });
      }
    } catch (e) {
      setState(() {
        _status += '\nError toggling like: $e';
      });
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      const int testOhyoId = 1;

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
        await client
            .from('favorites')
            .delete()
            .eq('id', existingFavorite['id']);
        setState(() {
          _isFavorited = false;
          _status += '\nUnfavorited successfully!';
        });
      } else {
        // Favorite
        await client
            .from('favorites')
            .insert({
              'user_id': user.id,
              'target_type': 'ohyo',
              'target_id': testOhyoId,
            });
        setState(() {
          _isFavorited = true;
          _status += '\nFavorited successfully!';
        });
      }
    } catch (e) {
      setState(() {
        _status += '\nError toggling favorite: $e';
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
          Text(_status, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          Text('Test Ohyo ID: 1', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                onPressed: _toggleLike,
                icon: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.grey,
                ),
              ),
              Text('$_likeCount likes'),
              const SizedBox(width: 20),
              IconButton(
                onPressed: _toggleFavorite,
                icon: Icon(
                  _isFavorited ? Icons.bookmark : Icons.bookmark_border,
                  color: _isFavorited ? Colors.teal : Colors.grey,
                ),
              ),
              Text(_isFavorited ? 'Favorited' : 'Not favorited'),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _testInteractions,
            child: const Text('Refresh Status'),
          ),
        ],
      ),
    );
  }
}
