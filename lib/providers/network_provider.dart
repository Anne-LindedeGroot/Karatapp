import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum NetworkStatus {
  unknown,
  connected,
  disconnected,
  checking,
}

class NetworkState {
  final NetworkStatus status;
  final String? lastError;
  final DateTime? lastChecked;
  final bool hasShownConnectionError;

  const NetworkState({
    required this.status,
    this.lastError,
    this.lastChecked,
    this.hasShownConnectionError = false,
  });

  NetworkState.initial()
      : status = NetworkStatus.unknown,
        lastError = null,
        lastChecked = null,
        hasShownConnectionError = false;

  NetworkState copyWith({
    NetworkStatus? status,
    String? lastError,
    DateTime? lastChecked,
    bool? hasShownConnectionError,
  }) {
    return NetworkState(
      status: status ?? this.status,
      lastError: lastError,
      lastChecked: lastChecked ?? this.lastChecked,
      hasShownConnectionError: hasShownConnectionError ?? this.hasShownConnectionError,
    );
  }

  bool get isConnected => status == NetworkStatus.connected;
  bool get isDisconnected => status == NetworkStatus.disconnected;
  bool get isChecking => status == NetworkStatus.checking;
}

class NetworkNotifier extends StateNotifier<NetworkState> {
  NetworkNotifier() : super(NetworkState.initial()) {
    _startPeriodicCheck();
  }

  Timer? _periodicTimer;
  static const Duration _checkInterval = Duration(seconds: 30);
  static const Duration _retryInterval = Duration(seconds: 5);

  void _startPeriodicCheck() {
    // Initial check
    checkConnection();
    
    // Periodic checks
    _periodicTimer = Timer.periodic(_checkInterval, (_) {
      if (state.isDisconnected) {
        // Check more frequently when disconnected
        checkConnection();
      } else {
        checkConnection();
      }
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  Future<void> checkConnection() async {
    if (state.isChecking) return; // Prevent multiple simultaneous checks

    state = state.copyWith(status: NetworkStatus.checking);

    try {
      // Try multiple connectivity checks for better reliability

      // First, try a simple HTTP request to a reliable endpoint
      final httpClient = HttpClient();
      httpClient.connectionTimeout = const Duration(seconds: 5);

      bool basicConnectivity = false;
      try {
        final request = await httpClient.headUrl(Uri.parse('https://www.google.com'));
        final response = await request.close();
        await response.drain(); // Consume the response

        if (response.statusCode == 200) {
          // Basic HTTP connectivity works
          basicConnectivity = true;
        }
      } catch (httpError) {
        debugPrint('HTTP connectivity check failed: $httpError');
      } finally {
        httpClient.close();
      }

      if (!basicConnectivity) {
        throw Exception('Basic internet connectivity failed');
      }

      // Only try Supabase if basic connectivity works
      final client = Supabase.instance.client;

      // Simple health check - try to get auth user (lightweight operation)
      // But be more lenient - if Supabase fails but basic internet works,
      // consider it partially connected
      try {
        await client.auth.getUser().timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw TimeoutException('Supabase connection timeout'),
        );

        // If we get here, full connection is working
        state = state.copyWith(
          status: NetworkStatus.connected,
          lastError: null,
          lastChecked: DateTime.now(),
        );
      } catch (supabaseError) {
        debugPrint('Supabase connectivity check failed, but basic internet works: $supabaseError');
        // Basic internet works, but Supabase doesn't - consider it connected for now
        // This prevents auth refresh loops when Supabase is temporarily down
        state = state.copyWith(
          status: NetworkStatus.connected,
          lastError: 'Supabase server temporarily unavailable',
          lastChecked: DateTime.now(),
        );
      }
    } catch (e) {
      final errorMessage = _getConnectionErrorMessage(e);

      state = state.copyWith(
        status: NetworkStatus.disconnected,
        lastError: errorMessage,
        lastChecked: DateTime.now(),
      );

      // Schedule retry for disconnected state
      if (!state.hasShownConnectionError) {
        state = state.copyWith(hasShownConnectionError: true);
        _scheduleRetry();
      }
    }
  }

  void _scheduleRetry() {
    Timer(_retryInterval, () {
      if (state.isDisconnected) {
        checkConnection();
      }
    });
  }

  String _getConnectionErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (error is SocketException) {
      return 'Geen internetverbinding beschikbaar';
    } else if (error is TimeoutException) {
      return 'Verbinding time-out - server reageert niet';
    } else if (errorString.contains('network')) {
      return 'Netwerkverbindingsprobleem';
    } else if (errorString.contains('dns') || errorString.contains('host')) {
      return 'Kan server niet bereiken';
    } else {
      return 'Verbindingsprobleem - controleer je internet';
    }
  }

  void markErrorAsShown() {
    state = state.copyWith(hasShownConnectionError: true);
  }

  void resetErrorShown() {
    state = state.copyWith(hasShownConnectionError: false);
  }

  // Manual retry method
  Future<void> retry() async {
    state = state.copyWith(hasShownConnectionError: false);
    await checkConnection();
  }
}

// Provider for network status
final networkProvider = StateNotifierProvider<NetworkNotifier, NetworkState>((ref) {
  return NetworkNotifier();
});

// Convenience providers
final isConnectedProvider = Provider<bool>((ref) {
  return ref.watch(networkProvider).isConnected;
});

final networkStatusProvider = Provider<NetworkStatus>((ref) {
  return ref.watch(networkProvider).status;
});

final shouldShowConnectionErrorProvider = Provider<bool>((ref) {
  final networkState = ref.watch(networkProvider);
  return networkState.isDisconnected && !networkState.hasShownConnectionError;
});
