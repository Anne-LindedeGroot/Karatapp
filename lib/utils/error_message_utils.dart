// Error message utilities for converting technical errors to user-friendly messages

String getUserFriendlyErrorMessage(String error) {
  final errorLower = error.toLowerCase();

  // RenderFlex overflow errors - these are UI layout issues
  if (errorLower.contains('renderflex') && errorLower.contains('overflow')) {
    return 'Layout issue detected. The interface has been adjusted.';
  }

  // Network-related errors
  if (errorLower.contains('network') ||
      errorLower.contains('connection') ||
      errorLower.contains('timeout') ||
      errorLower.contains('socket')) {
    return 'Verbindingsprobleem. Controleer je internetverbinding en probeer opnieuw.';
  }

  // Authentication errors
  if (errorLower.contains('unauthorized') ||
      errorLower.contains('invalid email or password') ||
      errorLower.contains('authentication')) {
    return 'Inloggen mislukt. Controleer je gegevens en probeer opnieuw.';
  }

  // Storage/Upload errors
  if (errorLower.contains('storage') ||
      errorLower.contains('upload') ||
      errorLower.contains('bucket')) {
    return 'Bestandsbewerking mislukt. Probeer het opnieuw.';
  }

  // Server errors
  if (errorLower.contains('server error') ||
      errorLower.contains('500') ||
      errorLower.contains('502') ||
      errorLower.contains('503')) {
    return 'Server is tijdelijk niet beschikbaar. Probeer het later opnieuw.';
  }

  // Rate limiting
  if (errorLower.contains('rate limit') ||
      errorLower.contains('too many requests')) {
    return 'Te veel verzoeken. Wacht even en probeer opnieuw.';
  }

  // Permission errors
  if (errorLower.contains('permission') ||
      errorLower.contains('access denied') ||
      errorLower.contains('forbidden')) {
    return 'Toegang geweigerd. Controleer je machtigingen en probeer opnieuw.';
  }

  // Return original error if no pattern matches, but clean it up
  return _cleanErrorMessage(error);
}

String getAuthErrorMessage(String? details) {
  if (details == null) {
    return 'Authenticatie mislukt. Probeer opnieuw in te loggen.';
  }

  final detailsLower = details.toLowerCase();
  if (detailsLower.contains('invalid email or password')) {
    return 'E-mailadres of wachtwoord is onjuist.';
  } else if (detailsLower.contains('email')) {
    return 'Voer een geldig e-mailadres in.';
  } else if (detailsLower.contains('password')) {
    return 'Wachtwoord moet minimaal 4 tekens zijn.';
  } else if (detailsLower.contains('already registered')) {
    return 'Dit e-mailadres is al geregistreerd. Log in met dit adres.';
  } else {
    return 'Authenticatie mislukt. Probeer het opnieuw.';
  }
}

String getValidationErrorMessage(String message) {
  return 'Controleer je invoer: ${_cleanErrorMessage(message)}';
}

String getUnknownErrorMessage(String? details) {
  if (details == null) {
    return 'Er is iets misgegaan. Probeer het opnieuw.';
  }
  return 'Onverwachte fout: ${_cleanErrorMessage(details)}';
}

String _cleanErrorMessage(String error) {
  // Define patterns for cleaning error messages
  const Pattern exceptionPattern = r'^Exception:\s*';
  const Pattern errorPattern = r'^Error:\s*';
  const Pattern failedPattern = r'^Failed to\s*';
  const Pattern nullPattern = r':\s*null$';

  // Remove common technical prefixes
  String cleaned = error
      .replaceAll(exceptionPattern, '')
      .replaceAll(errorPattern, '')
      .replaceAll(failedPattern, '')
      .replaceAll(nullPattern, '');

  // Capitalize first letter
  if (cleaned.isNotEmpty) {
    cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  // Ensure it ends with a period
  if (cleaned.isNotEmpty && !cleaned.endsWith('.')) {
    cleaned += '.';
  }

  return cleaned.isEmpty ? 'An error occurred.' : cleaned;
}



