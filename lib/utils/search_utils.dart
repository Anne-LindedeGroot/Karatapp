/// Search utility functions for friendly and tolerant search matching
class SearchUtils {
  /// Normalize text for search - handles diacritics, whitespace, and special characters
  /// This makes searches more tolerant of different input variations
  static String normalizeSearchText(String text) {
    if (text.isEmpty) return text;
    
    // Step 1: Convert to lowercase
    String normalized = text.toLowerCase();
    
    // Step 2: Normalize diacritics/accents (é -> e, ü -> u, etc.)
    // This allows "café" to match "cafe" and vice versa
    normalized = _removeDiacritics(normalized);
    
    // Step 3: Normalize whitespace (multiple spaces/tabs/newlines to single space)
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    
    // Step 4: Trim leading/trailing whitespace
    normalized = normalized.trim();
    
    // Step 5: Normalize common special characters that might be used interchangeably
    // Replace common punctuation that users might type differently
    // Smart quotes (U+2018, U+2019, U+201C, U+201D) to regular quotes
    normalized = normalized.replaceAll('\u2018', "'"); // Left single quotation mark
    normalized = normalized.replaceAll('\u2019', "'"); // Right single quotation mark
    normalized = normalized.replaceAll('\u201C', '"'); // Left double quotation mark
    normalized = normalized.replaceAll('\u201D', '"'); // Right double quotation mark
    normalized = normalized.replaceAll('\u2013', '-'); // En dash to hyphen
    normalized = normalized.replaceAll('\u2014', '-'); // Em dash to hyphen
    
    return normalized;
  }
  
  /// Remove diacritics/accents from text using character mapping
  /// Example: "café" -> "cafe", "Müller" -> "Muller"
  static String _removeDiacritics(String text) {
    const diacriticsMap = {
      'à': 'a', 'á': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a', 'å': 'a',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
      'ò': 'o', 'ó': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
      'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
      'ý': 'y', 'ÿ': 'y',
      'ç': 'c', 'ñ': 'n',
      'À': 'A', 'Á': 'A', 'Â': 'A', 'Ã': 'A', 'Ä': 'A', 'Å': 'A',
      'È': 'E', 'É': 'E', 'Ê': 'E', 'Ë': 'E',
      'Ì': 'I', 'Í': 'I', 'Î': 'I', 'Ï': 'I',
      'Ò': 'O', 'Ó': 'O', 'Ô': 'O', 'Õ': 'O', 'Ö': 'O',
      'Ù': 'U', 'Ú': 'U', 'Û': 'U', 'Ü': 'U',
      'Ý': 'Y',
      'Ç': 'C', 'Ñ': 'N',
    };
    
    return text.splitMapJoin('',
      onNonMatch: (char) => diacriticsMap[char] ?? char,
    );
  }
  
  /// Check if search query matches text (with normalization)
  /// This is a helper for contains-like matching with normalization
  static bool matchesNormalized(String text, String query) {
    final normalizedText = normalizeSearchText(text);
    final normalizedQuery = normalizeSearchText(query);
    return normalizedText.contains(normalizedQuery);
  }
  
  /// Check if search query starts with text (with normalization)
  static bool startsWithNormalized(String text, String query) {
    final normalizedText = normalizeSearchText(text);
    final normalizedQuery = normalizeSearchText(query);
    return normalizedText.startsWith(normalizedQuery);
  }
  
  /// Split text into words for word-based matching
  /// Handles various separators (spaces, dashes, dots, underscores)
  static List<String> splitIntoWords(String text) {
    final normalized = normalizeSearchText(text);
    return normalized.split(RegExp(r'[\s\-\._]+')).where((word) => word.isNotEmpty).toList();
  }
}

/// Extension on String to add normalize method
extension StringNormalize on String {
  String normalize() => SearchUtils.normalizeSearchText(this);
  
  bool containsNormalized(String query) => SearchUtils.matchesNormalized(this, query);
  
  bool startsWithNormalized(String query) => SearchUtils.startsWithNormalized(this, query);
  
  List<String> toWords() => SearchUtils.splitIntoWords(this);
}

