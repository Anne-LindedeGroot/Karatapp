import 'package:hive_flutter/hive_flutter.dart';

part 'local_storage.g.dart';

@HiveType(typeId: 0)
class CachedKata extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String? style;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime lastSynced;

  @HiveField(6)
  final List<String> imageUrls;

  @HiveField(7)
  final bool isFavorite;

  @HiveField(8)
  final bool needsSync;

  @HiveField(9)
  final bool isLiked;

  @HiveField(10)
  final int likeCount;

  CachedKata({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.lastSynced,
    required this.imageUrls,
    this.style,
    this.isFavorite = false,
    this.needsSync = false,
    this.isLiked = false,
    this.likeCount = 0,
  });
}

@HiveType(typeId: 1)
class CachedOhyo extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String? style;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime lastSynced;

  @HiveField(6)
  final List<String> imageUrls;

  @HiveField(7)
  final bool isFavorite;

  @HiveField(8)
  final bool needsSync;

  @HiveField(9)
  final bool isLiked;

  @HiveField(10)
  final int likeCount;

  CachedOhyo({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.lastSynced,
    required this.imageUrls,
    this.style,
    this.isFavorite = false,
    this.needsSync = false,
    this.isLiked = false,
    this.likeCount = 0,
  });
}

@HiveType(typeId: 2)
class CachedForumPost extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String content;
  
  @HiveField(3)
  final String authorId;
  
  @HiveField(4)
  final String authorName;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final DateTime lastSynced;
  
  @HiveField(7)
  final int likesCount;
  
  @HiveField(8)
  final int commentsCount;
  
  @HiveField(9)
  final bool needsSync;

  CachedForumPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.lastSynced,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.needsSync = false,
  });
}

class LocalStorage {
  static const String _katasBoxName = 'katas';
  static const String _ohyosBoxName = 'ohyos';
  static const String _forumPostsBoxName = 'forum_posts';
  static const String _settingsBoxName = 'settings';

  static Box<CachedKata>? _katasBox;
  static Box<CachedOhyo>? _ohyosBox;
  static Box<CachedForumPost>? _forumPostsBox;
  static Box<dynamic>? _settingsBox;
  
  static Future<void> initialize() async {
    // Register adapters only if not already registered
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CachedKataAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(CachedOhyoAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CachedForumPostAdapter());
    }

    // Open boxes
    _katasBox = await Hive.openBox<CachedKata>(_katasBoxName);
    _ohyosBox = await Hive.openBox<CachedOhyo>(_ohyosBoxName);
    _forumPostsBox = await Hive.openBox<CachedForumPost>(_forumPostsBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }
  
  // Kata operations
  static Future<void> saveKata(CachedKata kata) async {
    await _katasBox?.put(kata.id, kata);
  }
  
  static Future<void> saveKatas(List<CachedKata> katas) async {
    final Map<int, CachedKata> kataMap = {
      for (final kata in katas) kata.id: kata
    };
    await _katasBox?.putAll(kataMap);
  }
  
  static CachedKata? getKata(int id) {
    return _katasBox?.get(id);
  }
  
  static List<CachedKata> getAllKatas() {
    return _katasBox?.values.toList() ?? [];
  }
  
  static List<CachedKata> getFavoriteKatas() {
    return _katasBox?.values.where((kata) => kata.isFavorite).toList() ?? [];
  }
  
  static Future<void> deleteKata(int id) async {
    await _katasBox?.delete(id);
  }
  
  static Future<void> clearKatas() async {
    await _katasBox?.clear();
  }

  // Ohyo operations
  static Future<void> saveOhyo(CachedOhyo ohyo) async {
    await _ohyosBox?.put(ohyo.id, ohyo);
  }

  static Future<void> saveOhyos(List<CachedOhyo> ohyos) async {
    final Map<int, CachedOhyo> ohyoMap = {
      for (final ohyo in ohyos) ohyo.id: ohyo
    };
    await _ohyosBox?.putAll(ohyoMap);
  }

  static CachedOhyo? getOhyo(int id) {
    return _ohyosBox?.get(id);
  }

  static List<CachedOhyo> getAllOhyos() {
    return _ohyosBox?.values.toList() ?? [];
  }

  static List<CachedOhyo> getFavoriteOhyos() {
    return _ohyosBox?.values.where((ohyo) => ohyo.isFavorite).toList() ?? [];
  }

  static Future<void> deleteOhyo(int id) async {
    await _ohyosBox?.delete(id);
  }

  static Future<void> clearOhyos() async {
    await _ohyosBox?.clear();
  }

  // Forum post operations
  static Future<void> saveForumPost(CachedForumPost post) async {
    await _forumPostsBox?.put(post.id, post);
  }
  
  static Future<void> saveForumPosts(List<CachedForumPost> posts) async {
    final Map<String, CachedForumPost> postMap = {
      for (final post in posts) post.id: post
    };
    await _forumPostsBox?.putAll(postMap);
  }
  
  static CachedForumPost? getForumPost(String id) {
    return _forumPostsBox?.get(id);
  }
  
  static List<CachedForumPost> getAllForumPosts() {
    return _forumPostsBox?.values.toList() ?? [];
  }
  
  static Future<void> deleteForumPost(String id) async {
    await _forumPostsBox?.delete(id);
  }
  
  static Future<void> clearForumPosts() async {
    await _forumPostsBox?.clear();
  }
  
  // Settings operations
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox?.put(key, value);
  }
  
  static T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox?.get(key, defaultValue: defaultValue) as T?;
  }
  
  static Future<void> deleteSetting(String key) async {
    await _settingsBox?.delete(key);
  }
  
  static Future<void> clearSettings() async {
    await _settingsBox?.clear();
  }
  
  // Authentication persistence
  static Future<void> saveAuthSession(String accessToken, String refreshToken, String userId) async {
    await Future.wait([
      saveSetting('auth_access_token', accessToken),
      saveSetting('auth_refresh_token', refreshToken),
      saveSetting('auth_user_id', userId),
      saveSetting('auth_session_timestamp', DateTime.now().millisecondsSinceEpoch),
    ]);
  }
  
  static Map<String, String?> getAuthSession() {
    return {
      'access_token': getSetting<String>('auth_access_token'),
      'refresh_token': getSetting<String>('auth_refresh_token'),
      'user_id': getSetting<String>('auth_user_id'),
    };
  }
  
  static DateTime? getAuthSessionTimestamp() {
    final timestamp = getSetting<int>('auth_session_timestamp');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  
  static Future<void> clearAuthSession() async {
    await Future.wait([
      deleteSetting('auth_access_token'),
      deleteSetting('auth_refresh_token'),
      deleteSetting('auth_user_id'),
      deleteSetting('auth_session_timestamp'),
    ]);
  }
  
  static bool get hasValidAuthSession {
    final session = getAuthSession();
    final timestamp = getAuthSessionTimestamp();
    
    // Check if we have required tokens
    if (session['refresh_token'] == null) {
      return false;
    }
    
    // If we have a timestamp, check if session is not older than 60 days
    if (timestamp != null) {
      final daysSinceAuth = DateTime.now().difference(timestamp).inDays;
      return daysSinceAuth < 60; // Increased from 30 to 60 days
    }
    
    // If no timestamp but we have refresh token, consider it valid
    // (for backward compatibility with existing sessions)
    return true;
  }
  
  // Utility methods
  static Future<void> clearAllData() async {
    await clearKatas();
    await clearForumPosts();
    await clearSettings();
  }
  
  static DateTime? getLastSyncTime() {
    final timestamp = getSetting<int>('last_sync_time');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  
  static Future<void> setLastSyncTime(DateTime time) async {
    await saveSetting('last_sync_time', time.millisecondsSinceEpoch);
  }
  
  static bool get isFirstLaunch {
    return getSetting<bool>('is_first_launch', defaultValue: true) ?? true;
  }
  
  static Future<void> setFirstLaunchComplete() async {
    await saveSetting('is_first_launch', false);
  }
}
