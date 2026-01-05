class ErrorBoundaryState {
  final String? error;
  final StackTrace? stackTrace;
  final DateTime? timestamp;
  final bool isVisible;

  const ErrorBoundaryState({
    this.error,
    this.stackTrace,
    this.timestamp,
    this.isVisible = false,
  });

  ErrorBoundaryState.initial()
    : error = null,
      stackTrace = null,
      timestamp = null,
      isVisible = false;

  ErrorBoundaryState copyWith({
    String? error,
    StackTrace? stackTrace,
    DateTime? timestamp,
    bool? isVisible,
  }) {
    return ErrorBoundaryState(
      error: error,
      stackTrace: stackTrace,
      timestamp: timestamp,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  String toString() {
    return 'ErrorBoundaryState(error: $error, isVisible: $isVisible, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorBoundaryState &&
        other.error == error &&
        other.stackTrace == stackTrace &&
        other.timestamp == timestamp &&
        other.isVisible == isVisible;
  }

  @override
  int get hashCode {
    return error.hashCode ^
        stackTrace.hashCode ^
        timestamp.hashCode ^
        isVisible.hashCode;
  }
}


