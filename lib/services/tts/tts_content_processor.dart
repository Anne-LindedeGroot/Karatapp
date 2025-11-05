
/// TTS Content Processor - Handles Dutch text processing and formatting
class TTSContentProcessor {
  /// Process content for better Dutch speech pronunciation
  static String processContentForDutchSpeech(String content) {
    if (content.isEmpty) return content;
    
    // Clean up the content for better speech
    String processed = content;
    
    // Remove excessive whitespace and normalize
    processed = processed.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Remove UI element descriptions to make speech more natural
    processed = processed.replaceAll(RegExp(r'Knop:\s*', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Zwevende knop:\s*', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Filter:\s*', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Invoerveld:\s*', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Pagina:\s*', caseSensitive: false), '');
    
    // Remove redundant phrases that make speech unnatural
    processed = processed.replaceAll(RegExp(r'Dit is de\s+', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Dit zijn de\s+', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Dit is je\s+', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Dit zijn je\s+', caseSensitive: false), '');
    
    // Clean up multiple dots and spaces
    processed = processed.replaceAll(RegExp(r'\.\s*\.\s*\.'), '.');
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');
    
    // Add natural pauses for better readability
    processed = processed.replaceAll(RegExp(r'\.\s*'), '. ');
    processed = processed.replaceAll(RegExp(r'!\s*'), '! ');
    processed = processed.replaceAll(RegExp(r'\?\s*'), '? ');
    
    // Handle common abbreviations and acronyms for better pronunciation
    processed = processed.replaceAll(RegExp(r'\bTTS\b', caseSensitive: false), 'T T S');
    processed = processed.replaceAll(RegExp(r'\bAPI\b', caseSensitive: false), 'A P I');
    processed = processed.replaceAll(RegExp(r'\bURL\b', caseSensitive: false), 'U R L');
    
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
    processed = processed.replaceAll(RegExp(r'\bDr\.', caseSensitive: false), 'Dokter');
    processed = processed.replaceAll(RegExp(r'\bProf\.', caseSensitive: false), 'Professor');
    processed = processed.replaceAll(RegExp(r'\bMr\.', caseSensitive: false), 'Meneer');
    processed = processed.replaceAll(RegExp(r'\bMevr\.', caseSensitive: false), 'Mevrouw');
    
    // Handle numbers
    processed = _pronounceNumbers(processed);
    
    // Handle email addresses
    processed = _pronounceEmails(processed);
    
    // Clean up extra spaces
    processed = processed.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return processed;
  }

  /// Pronounce numbers in Dutch
  static String _pronounceNumbers(String text) {
    // Simple number pronunciation - can be enhanced
    return text.replaceAllMapped(RegExp(r'\b(\d+)\b'), (match) {
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
    return text.replaceAllMapped(RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), (match) {
      final email = match.group(0)!;
      return _pronounceEmail(email);
    });
  }

  /// Pronounce email addresses in Dutch
  static String _pronounceEmail(String email) {
    return email.replaceAll('@', ' at ').replaceAll('.', ' punt ');
  }
}
