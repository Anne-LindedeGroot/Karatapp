
/// TTS Content Processor - Handles Dutch text processing and formatting
class TTSContentProcessor {
  // Pattern constants for text processing
  static final Pattern _whitespaceRegex = RegExp(r'\s+'); // ignore: deprecated_member_use
  static final Pattern _buttonRegex = RegExp(r'Knop:\s*', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _floatingButtonRegex = RegExp(r'Zwevende knop:\s*', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _filterRegex = RegExp(r'Filter:\s*', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _inputFieldRegex = RegExp(r'Invoerveld:\s*', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _pageRegex = RegExp(r'Pagina:\s*', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _ditIsDeRegex = RegExp(r'Dit is de\s+', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _ditZijnDeRegex = RegExp(r'Dit zijn de\s+', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _ditIsJeRegex = RegExp(r'Dit is je\s+', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _ditZijnJeRegex = RegExp(r'Dit zijn je\s+', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _multipleDotsRegex = RegExp(r'\.\s*\.\s*\.'); // ignore: deprecated_member_use
  static final Pattern _dotSpaceRegex = RegExp(r'\.\s*'); // ignore: deprecated_member_use
  static final Pattern _exclamationSpaceRegex = RegExp(r'!\s*'); // ignore: deprecated_member_use
  static final Pattern _questionSpaceRegex = RegExp(r'\?\s*'); // ignore: deprecated_member_use
  static final Pattern _ttsAbbrevRegex = RegExp(r'\bTTS\b', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _apiAbbrevRegex = RegExp(r'\bAPI\b', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _urlAbbrevRegex = RegExp(r'\bURL\b', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _drRegex = RegExp(r'\bDr\.', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _profRegex = RegExp(r'\bProf\.', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _mrRegex = RegExp(r'\bMr\.', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _mevrRegex = RegExp(r'\bMevr\.', caseSensitive: false); // ignore: deprecated_member_use
  static final Pattern _numberRegex = RegExp(r'\b(\d+)\b'); // ignore: deprecated_member_use
  static final Pattern _emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'); // ignore: deprecated_member_use
  /// Process content for better Dutch speech pronunciation
  static String processContentForDutchSpeech(String content) {
    if (content.isEmpty) return content;
    
    // Clean up the content for better speech
    String processed = content;
    
    // Remove excessive whitespace and normalize
    processed = processed.replaceAll(_whitespaceRegex, ' ').trim();

    // Remove UI element descriptions to make speech more natural
    processed = processed.replaceAll(_buttonRegex, '');
    processed = processed.replaceAll(_floatingButtonRegex, '');
    processed = processed.replaceAll(_filterRegex, '');
    processed = processed.replaceAll(_inputFieldRegex, '');
    processed = processed.replaceAll(_pageRegex, '');

    // Remove redundant phrases that make speech unnatural
    processed = processed.replaceAll(_ditIsDeRegex, '');
    processed = processed.replaceAll(_ditZijnDeRegex, '');
    processed = processed.replaceAll(_ditIsJeRegex, '');
    processed = processed.replaceAll(_ditZijnJeRegex, '');

    // Clean up multiple dots and spaces
    processed = processed.replaceAll(_multipleDotsRegex, '.');
    processed = processed.replaceAll(_whitespaceRegex, ' ');

    // Add natural pauses for better readability
    processed = processed.replaceAll(_dotSpaceRegex, '. ');
    processed = processed.replaceAll(_exclamationSpaceRegex, '! ');
    processed = processed.replaceAll(_questionSpaceRegex, '? ');

    // Handle common abbreviations and acronyms for better pronunciation
    processed = processed.replaceAll(_ttsAbbrevRegex, 'T T S');
    processed = processed.replaceAll(_apiAbbrevRegex, 'A P I');
    processed = processed.replaceAll(_urlAbbrevRegex, 'U R L');
    
    // Ensure proper sentence endings
    if (!processed.endsWith('.') && !processed.endsWith('!') && !processed.endsWith('?')) {
      processed += '.';
    }
    
    return processed.trim();
  }

  /// Process Dutch text for better speech pronunciation
  static String processDutchText(String text) {
    if (text.isEmpty) return text;
    
    String processed = text;
    
    // Handle common Dutch abbreviations
    processed = processed.replaceAll(_drRegex, 'Dokter');
    processed = processed.replaceAll(_profRegex, 'Professor');
    processed = processed.replaceAll(_mrRegex, 'Meneer');
    processed = processed.replaceAll(_mevrRegex, 'Mevrouw');

    // Handle numbers
    processed = _pronounceNumbers(processed);

    // Handle email addresses
    processed = _pronounceEmails(processed);

    // Clean up extra spaces
    processed = processed.replaceAll(_whitespaceRegex, ' ').trim();
    
    return processed;
  }

  /// Pronounce numbers in Dutch
  static String _pronounceNumbers(String text) {
    // Simple number pronunciation - can be enhanced
    return text.replaceAllMapped(_numberRegex, (match) {
      final number = match.group(1)!;
      return _pronounceNumber(number);
    });
  }

  /// Pronounce a single number in Dutch
  static String _pronounceNumber(String number) {
    // Basic number pronunciation - can be enhanced for complex numbers
    return number;
  }

  /// Pronounce email addresses in Dutch
  static String _pronounceEmails(String text) {
    return text.replaceAllMapped(_emailRegex, (match) {
      final email = match.group(0)!;
      return _pronounceEmail(email);
    });
  }

  /// Pronounce email addresses in Dutch
  static String _pronounceEmail(String email) {
    return email.replaceAll('@', ' at ').replaceAll('.', ' punt ');
  }
}
