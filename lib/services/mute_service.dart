import 'package:supabase_flutter/supabase_flutter.dart';

enum MuteDuration {
  oneDay(Duration(days: 1), '1 Day', 'Short timeout for minor issues'),
  threeDays(Duration(days: 3), '3 Days', 'Standard timeout for rule violations'),
  oneWeek(Duration(days: 7), '1 Week', 'Extended timeout for repeated violations'),
  oneMonth(Duration(days: 30), '1 Month', 'Serious violations or harassment'),
  threeMonths(Duration(days: 90), '3 Months', 'Severe violations or toxic behavior'),
  sixMonths(Duration(days: 180), '6 Months', 'Major violations requiring long break'),
  oneYear(Duration(days: 365), '1 Year', 'Extreme cases requiring extended separation');

  const MuteDuration(this.duration, this.displayName, this.description);
  
  final Duration duration;
  final String displayName;
  final String description;
}

class MuteInfo {
  final String id;
  final String userId;
  final String mutedBy;
  final String reason;
  final DateTime mutedAt;
  final DateTime mutedUntil;
  final bool isActive;
  final DateTime? unmutedAt;
  final String? unmutedBy;

  MuteInfo({
    required this.id,
    required this.userId,
    required this.mutedBy,
    required this.reason,
    required this.mutedAt,
    required this.mutedUntil,
    required this.isActive,
    this.unmutedAt,
    this.unmutedBy,
  });

  factory MuteInfo.fromJson(Map<String, dynamic> json) {
    return MuteInfo(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mutedBy: json['muted_by'] as String,
      reason: json['reason'] as String,
      mutedAt: DateTime.parse(json['muted_at'] as String),
      mutedUntil: DateTime.parse(json['muted_until'] as String),
      isActive: json['is_active'] as bool,
      unmutedAt: json['unmuted_at'] != null 
          ? DateTime.parse(json['unmuted_at'] as String) 
          : null,
      unmutedBy: json['unmuted_by'] as String?,
    );
  }

  bool get isExpired => DateTime.now().isAfter(mutedUntil);
  
  Duration get timeRemaining {
    if (isExpired) return Duration.zero;
    return mutedUntil.difference(DateTime.now());
  }

  String get timeRemainingText {
    if (isExpired) return 'Expired';
    
    final remaining = timeRemaining;
    if (remaining.inDays > 0) {
      return '${remaining.inDays} day${remaining.inDays == 1 ? '' : 's'}';
    } else if (remaining.inHours > 0) {
      return '${remaining.inHours} hour${remaining.inHours == 1 ? '' : 's'}';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} minute${remaining.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Less than a minute';
    }
  }
}

class MuteService {
  final SupabaseClient _client = Supabase.instance.client;

  // Check if a user is currently muted
  Future<bool> isUserMuted(String userId) async {
    try {
      // First, clean up expired mutes
      await _cleanupExpiredMutes();

      final response = await _client
          .from('user_mutes')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .gt('muted_until', DateTime.now().toIso8601String())
          .limit(1)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('MuteService: Error checking if user is muted: $e');
      return false;
    }
  }

  // Get current mute info for a user
  Future<MuteInfo?> getCurrentMute(String userId) async {
    try {
      // First, clean up expired mutes
      await _cleanupExpiredMutes();

      final response = await _client
          .from('user_mutes')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .gt('muted_until', DateTime.now().toIso8601String())
          .order('muted_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      return MuteInfo.fromJson(response);
    } catch (e) {
      print('MuteService: Error getting current mute: $e');
      return null;
    }
  }

  // Mute a user
  Future<bool> muteUser({
    required String userId,
    required MuteDuration duration,
    required String reason,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Check if current user can mute (should be host)
      // This will be enforced by RLS policies as well
      
      final mutedUntil = DateTime.now().add(duration.duration);

      // Deactivate any existing active mutes for this user
      await _client
          .from('user_mutes')
          .update({
            'is_active': false,
            'unmuted_at': DateTime.now().toIso8601String(),
            'unmuted_by': currentUser.id,
          })
          .eq('user_id', userId)
          .eq('is_active', true);

      // Insert new mute
      await _client
          .from('user_mutes')
          .insert({
            'user_id': userId,
            'muted_by': currentUser.id,
            'reason': reason,
            'muted_until': mutedUntil.toIso8601String(),
          });

      print('MuteService: Successfully muted user $userId until $mutedUntil');
      return true;
    } catch (e) {
      print('MuteService: Error muting user: $e');
      return false;
    }
  }

  // Unmute a user early
  Future<bool> unmuteUser(String userId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      await _client
          .from('user_mutes')
          .update({
            'is_active': false,
            'unmuted_at': DateTime.now().toIso8601String(),
            'unmuted_by': currentUser.id,
          })
          .eq('user_id', userId)
          .eq('is_active', true);

      print('MuteService: Successfully unmuted user $userId');
      return true;
    } catch (e) {
      print('MuteService: Error unmuting user: $e');
      return false;
    }
  }

  // Get all mutes for a user (history)
  Future<List<MuteInfo>> getUserMuteHistory(String userId) async {
    try {
      final response = await _client
          .from('user_mutes')
          .select('*')
          .eq('user_id', userId)
          .order('muted_at', ascending: false);

      return response.map<MuteInfo>((json) => MuteInfo.fromJson(json)).toList();
    } catch (e) {
      print('MuteService: Error getting user mute history: $e');
      return [];
    }
  }

  // Get all active mutes (for admin view)
  Future<List<MuteInfo>> getAllActiveMutes() async {
    try {
      // First, clean up expired mutes
      await _cleanupExpiredMutes();

      final response = await _client
          .from('user_mutes')
          .select('*')
          .eq('is_active', true)
          .gt('muted_until', DateTime.now().toIso8601String())
          .order('muted_at', ascending: false);

      return response.map<MuteInfo>((json) => MuteInfo.fromJson(json)).toList();
    } catch (e) {
      print('MuteService: Error getting all active mutes: $e');
      return [];
    }
  }

  // Clean up expired mutes (called automatically)
  Future<void> _cleanupExpiredMutes() async {
    try {
      await _client
          .from('user_mutes')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('is_active', true)
          .lt('muted_until', DateTime.now().toIso8601String());
    } catch (e) {
      print('MuteService: Error cleaning up expired mutes: $e');
    }
  }

  // Check if current user can mute others
  Future<bool> canMuteUsers() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      final response = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', currentUser.id)
          .order('granted_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return false;

      final role = response['role'] as String;
      return role == 'host' || role == 'mediator'; // Hosts and mediators can mute users
    } catch (e) {
      print('MuteService: Error checking mute permissions: $e');
      return false;
    }
  }

  // Get mute statistics
  Future<Map<String, int>> getMuteStatistics() async {
    try {
      final activeMutes = await _client
          .from('user_mutes')
          .select('id')
          .eq('is_active', true)
          .gt('muted_until', DateTime.now().toIso8601String());

      final totalMutes = await _client
          .from('user_mutes')
          .select('id');

      final expiredToday = await _client
          .from('user_mutes')
          .select('id')
          .eq('is_active', false)
          .gte('unmuted_at', DateTime.now().subtract(const Duration(days: 1)).toIso8601String());

      return {
        'active': activeMutes.length,
        'total': totalMutes.length,
        'expired_today': expiredToday.length,
      };
    } catch (e) {
      print('MuteService: Error getting mute statistics: $e');
      return {
        'active': 0,
        'total': 0,
        'expired_today': 0,
      };
    }
  }
}
