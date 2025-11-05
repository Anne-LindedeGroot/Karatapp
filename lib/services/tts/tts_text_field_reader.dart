import 'package:flutter/material.dart';

/// Specialized TTS Text Field Reader
/// This service provides enhanced text reading for text fields, forms, and input areas
class TTSTextFieldReader {
  /// Read all text fields on the current screen with their labels and values
  static String readAllTextFields(BuildContext context) {
    final List<String> textFieldReadings = [];
    
    try {
      debugPrint('TTS TextFieldReader: Starting text field extraction...');
      
      // Extract text fields from the widget tree
      final textFields = _extractAllTextFields(context);
      
      if (textFields.isEmpty) {
        debugPrint('TTS TextFieldReader: No text fields found');
        return 'Geen tekstvelden gevonden op deze pagina';
      }
      
      debugPrint('TTS TextFieldReader: Found ${textFields.length} text fields');
      
      // Process each text field
      for (int i = 0; i < textFields.length; i++) {
        final field = textFields[i];
        final reading = _formatTextFieldForSpeech(field, i + 1);
        if (reading.isNotEmpty) {
          textFieldReadings.add(reading);
        }
      }
      
      final result = textFieldReadings.join('. ');
      debugPrint('TTS TextFieldReader: Generated reading: $result');
      return result;
      
    } catch (e) {
      debugPrint('TTS TextFieldReader: Error reading text fields: $e');
      return 'Fout bij het lezen van tekstvelden';
    }
  }

  /// Read a specific text field by its label or hint
  static String readSpecificTextField(BuildContext context, String fieldIdentifier) {
    try {
      debugPrint('TTS TextFieldReader: Looking for field: $fieldIdentifier');
      
      final textFields = _extractAllTextFields(context);
      
      for (final field in textFields) {
        if (_matchesField(field, fieldIdentifier)) {
          final reading = _formatTextFieldForSpeech(field, 1);
          debugPrint('TTS TextFieldReader: Found matching field: $reading');
          return reading;
        }
      }
      
      debugPrint('TTS TextFieldReader: No field found matching: $fieldIdentifier');
      return 'Tekstveld niet gevonden: $fieldIdentifier';
      
    } catch (e) {
      debugPrint('TTS TextFieldReader: Error reading specific field: $e');
      return 'Fout bij het lezen van tekstveld';
    }
  }

  /// Extract all text fields from the widget tree
  static List<TextFieldInfo> _extractAllTextFields(BuildContext context) {
    final List<TextFieldInfo> textFields = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        
        if (widget is TextFormField) {
          final info = _extractTextFieldInfo(widget, 'TextFormField');
          if (info != null) {
            textFields.add(info);
          }
        } else if (widget is TextField) {
          final info = _extractTextFieldInfo(widget, 'TextField');
          if (info != null) {
            textFields.add(info);
          }
        } else if (widget.runtimeType.toString().contains('EnhancedAccessibleTextField')) {
          // Handle EnhancedAccessibleTextField specifically
          final info = _extractEnhancedTextFieldInfo(widget);
          if (info != null) {
            textFields.add(info);
          }
        }
      });
    } catch (e) {
      debugPrint('TTS TextFieldReader: Error extracting text fields: $e');
    }
    
    return textFields;
  }

  /// Extract information from EnhancedAccessibleTextField widget
  static TextFieldInfo? _extractEnhancedTextFieldInfo(dynamic enhancedTextField) {
    try {
      // Try to access the decoration property
      final decoration = enhancedTextField.decoration;
      if (decoration == null) return null;
      
      // Get the controller
      final controller = enhancedTextField.controller;
      String value = '';
      if (controller != null && controller.text != null) {
        value = controller.text;
      }
      
      return TextFieldInfo(
        label: decoration.labelText ?? '',
        hint: decoration.hintText ?? '',
        value: value,
        type: 'EnhancedAccessibleTextField',
        isRequired: decoration.labelText?.contains('*') == true,
        isPassword: enhancedTextField.obscureText == true,
      );
    } catch (e) {
      debugPrint('TTS TextFieldReader: Error extracting enhanced field info: $e');
      return null;
    }
  }

  /// Extract information from a text field widget
  static TextFieldInfo? _extractTextFieldInfo(dynamic textField, String type) {
    try {
      final decoration = textField.decoration;
      if (decoration == null) return null;
      
      return TextFieldInfo(
        label: decoration.labelText ?? '',
        hint: decoration.hintText ?? '',
        value: textField.controller?.text ?? '',
        type: type,
        isRequired: decoration.labelText?.contains('*') == true,
        isPassword: textField.obscureText == true,
      );
    } catch (e) {
      debugPrint('TTS TextFieldReader: Error extracting field info: $e');
      return null;
    }
  }

  /// Check if a field matches the given identifier
  static bool _matchesField(TextFieldInfo field, String identifier) {
    final lowerIdentifier = identifier.toLowerCase();
    
    return field.label.toLowerCase().contains(lowerIdentifier) ||
           field.hint.toLowerCase().contains(lowerIdentifier) ||
           field.type.toLowerCase().contains(lowerIdentifier);
  }

  /// Format a text field for speech output
  static String _formatTextFieldForSpeech(TextFieldInfo field, int position) {
    final List<String> parts = [];
    
    // Add field label or hint
    if (field.label.isNotEmpty) {
      parts.add('${field.label}${field.isRequired ? ' (verplicht)' : ''}');
    } else if (field.hint.isNotEmpty) {
      parts.add('${field.hint}${field.isRequired ? ' (verplicht)' : ''}');
    } else {
      parts.add('Tekstveld $position');
    }
    
    // Add field type information
    if (field.isPassword) {
      parts.add('wachtwoord veld');
    }
    
    // Add current value
    if (field.value.isNotEmpty) {
      if (field.isPassword) {
        parts.add('ingevuld met ${field.value.length} karakters');
      } else {
        parts.add('bevat: ${field.value}');
      }
    } else {
      parts.add('is leeg');
    }
    
    return parts.join(', ');
  }

  /// Read profile name fields specifically
  static String readProfileNameFields(BuildContext context) {
    try {
      debugPrint('TTS TextFieldReader: Reading profile name fields...');
      
      final textFields = _extractAllTextFields(context);
      final nameFields = textFields.where((field) => 
        _isNameField(field)).toList();
      
      if (nameFields.isEmpty) {
        return 'Geen naamvelden gevonden';
      }
      
      final readings = nameFields.map((field) => 
        _formatTextFieldForSpeech(field, 1)).toList();
      
      return readings.join('. ');
      
    } catch (e) {
      debugPrint('TTS TextFieldReader: Error reading profile names: $e');
      return 'Fout bij het lezen van naamvelden';
    }
  }

  /// Check if a field is a name field
  static bool _isNameField(TextFieldInfo field) {
    final lowerLabel = field.label.toLowerCase();
    final lowerHint = field.hint.toLowerCase();
    
    return lowerLabel.contains('naam') ||
           lowerLabel.contains('name') ||
           lowerHint.contains('naam') ||
           lowerHint.contains('name') ||
           lowerLabel.contains('volledige') ||
           lowerHint.contains('volledige');
  }

  /// Read login/register form fields
  static String readAuthFormFields(BuildContext context) {
    try {
      debugPrint('TTS TextFieldReader: Reading auth form fields...');
      
      final textFields = _extractAllTextFields(context);
      final authFields = textFields.where((field) => 
        _isAuthField(field)).toList();
      
      if (authFields.isEmpty) {
        return 'Geen inlogvelden gevonden';
      }
      
      final readings = authFields.map((field) => 
        _formatTextFieldForSpeech(field, 1)).toList();
      
      return readings.join('. ');
      
    } catch (e) {
      debugPrint('TTS TextFieldReader: Error reading auth fields: $e');
      return 'Fout bij het lezen van inlogvelden';
    }
  }

  /// Check if a field is an authentication field
  static bool _isAuthField(TextFieldInfo field) {
    final lowerLabel = field.label.toLowerCase();
    final lowerHint = field.hint.toLowerCase();
    
    return lowerLabel.contains('e-mail') ||
           lowerLabel.contains('email') ||
           lowerLabel.contains('wachtwoord') ||
           lowerLabel.contains('password') ||
           lowerLabel.contains('naam') ||
           lowerLabel.contains('name') ||
           lowerLabel.contains('volledige') ||
           lowerLabel.contains('bevestig') ||
           lowerLabel.contains('confirm') ||
           lowerHint.contains('e-mail') ||
           lowerHint.contains('email') ||
           lowerHint.contains('wachtwoord') ||
           lowerHint.contains('password') ||
           lowerHint.contains('naam') ||
           lowerHint.contains('name') ||
           lowerHint.contains('volledige') ||
           lowerHint.contains('bevestig') ||
           lowerHint.contains('confirm') ||
           field.isPassword;
  }

  /// Read kata/post creation/editing fields
  static String readContentFormFields(BuildContext context) {
    try {
      debugPrint('TTS TextFieldReader: Reading content form fields...');
      
      final textFields = _extractAllTextFields(context);
      final contentFields = textFields.where((field) => 
        _isContentField(field)).toList();
      
      if (contentFields.isEmpty) {
        return 'Geen inhoudsvelden gevonden';
      }
      
      final readings = contentFields.map((field) => 
        _formatTextFieldForSpeech(field, 1)).toList();
      
      return readings.join('. ');
      
    } catch (e) {
      debugPrint('TTS TextFieldReader: Error reading content fields: $e');
      return 'Fout bij het lezen van inhoudsvelden';
    }
  }

  /// Check if a field is a content field (kata/post)
  static bool _isContentField(TextFieldInfo field) {
    final lowerLabel = field.label.toLowerCase();
    final lowerHint = field.hint.toLowerCase();
    
    return lowerLabel.contains('kata') ||
           lowerLabel.contains('titel') ||
           lowerLabel.contains('title') ||
           lowerLabel.contains('beschrijving') ||
           lowerLabel.contains('description') ||
           lowerLabel.contains('inhoud') ||
           lowerLabel.contains('content') ||
           lowerLabel.contains('stijl') ||
           lowerLabel.contains('style') ||
           lowerHint.contains('kata') ||
           lowerHint.contains('titel') ||
           lowerHint.contains('title') ||
           lowerHint.contains('beschrijving') ||
           lowerHint.contains('description') ||
           lowerHint.contains('inhoud') ||
           lowerHint.contains('content') ||
           lowerHint.contains('stijl') ||
           lowerHint.contains('style');
  }

  /// Read media-related form fields (video URLs, image descriptions, etc.)
  static String readMediaFormFields(BuildContext context) {
    try {
      debugPrint('TTS TextFieldReader: Reading media form fields...');
      
      final textFields = _extractAllTextFields(context);
      final mediaFields = textFields.where((field) => 
        _isMediaField(field)).toList();
      
      if (mediaFields.isEmpty) {
        return 'Geen media velden gevonden';
      }
      
      final readings = mediaFields.map((field) => 
        _formatMediaFieldForSpeech(field, 1)).toList();
      
      return readings.join('. ');
      
    } catch (e) {
      debugPrint('TTS TextFieldReader: Error reading media fields: $e');
      return 'Fout bij het lezen van media velden';
    }
  }

  /// Check if a field is a media-related field
  static bool _isMediaField(TextFieldInfo field) {
    final lowerLabel = field.label.toLowerCase();
    final lowerHint = field.hint.toLowerCase();
    
    return lowerLabel.contains('video') ||
           lowerLabel.contains('url') ||
           lowerLabel.contains('link') ||
           lowerLabel.contains('afbeelding') ||
           lowerLabel.contains('foto') ||
           lowerLabel.contains('image') ||
           lowerLabel.contains('media') ||
           lowerHint.contains('video') ||
           lowerHint.contains('url') ||
           lowerHint.contains('link') ||
           lowerHint.contains('afbeelding') ||
           lowerHint.contains('foto') ||
           lowerHint.contains('image') ||
           lowerHint.contains('media') ||
           lowerHint.contains('youtube') ||
           lowerHint.contains('vimeo') ||
           _isValidUrl(field.value) && _isMediaUrl(field.value);
  }

  /// Format a media field for speech output with enhanced descriptions
  static String _formatMediaFieldForSpeech(TextFieldInfo field, int position) {
    final List<String> parts = [];
    
    // Add field label or hint
    if (field.label.isNotEmpty) {
      parts.add('${field.label}${field.isRequired ? ' (verplicht)' : ''}');
    } else if (field.hint.isNotEmpty) {
      parts.add('${field.hint}${field.isRequired ? ' (verplicht)' : ''}');
    } else {
      parts.add('Media veld $position');
    }
    
    // Add field type information
    if (field.isPassword) {
      parts.add('wachtwoord veld');
    }
    
    // Add current value with enhanced media descriptions
    if (field.value.isNotEmpty) {
      if (field.isPassword) {
        parts.add('ingevuld met ${field.value.length} karakters');
      } else if (_isValidUrl(field.value) && _isMediaUrl(field.value)) {
        final mediaDescription = _getMediaDescription(field.value);
        parts.add('bevat: $mediaDescription');
      } else {
        parts.add('bevat: ${field.value}');
      }
    } else {
      parts.add('is leeg');
    }
    
    return parts.join(', ');
  }

  /// Check if a string is a valid URL
  static bool _isValidUrl(String url) {
    if (url.trim().isEmpty) return false;
    
    try {
      final uri = Uri.parse(url.trim());
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Check if a URL is a media URL
  static bool _isMediaUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    // Video platforms
    if (lowerUrl.contains('youtube.com') || 
        lowerUrl.contains('youtu.be') ||
        lowerUrl.contains('vimeo.com') ||
        lowerUrl.contains('dailymotion.com') ||
        lowerUrl.contains('twitch.tv')) {
      return true;
    }
    
    // Direct video file extensions
    final videoExtensions = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv', '.m4v'];
    if (videoExtensions.any((ext) => lowerUrl.endsWith(ext))) {
      return true;
    }
    
    // Audio file extensions
    final audioExtensions = ['.mp3', '.wav', '.aac', '.ogg', '.flac', '.m4a'];
    if (audioExtensions.any((ext) => lowerUrl.endsWith(ext))) {
      return true;
    }
    
    // Image file extensions
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg'];
    if (imageExtensions.any((ext) => lowerUrl.endsWith(ext))) {
      return true;
    }
    
    return false;
  }

  /// Get a descriptive name for media content
  static String _getMediaDescription(String url) {
    try {
      final uri = Uri.parse(url);
      
      // YouTube
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        return 'YouTube video link';
      }
      
      // Vimeo
      if (uri.host.contains('vimeo.com')) {
        return 'Vimeo video link';
      }
      
      // Dailymotion
      if (uri.host.contains('dailymotion.com')) {
        return 'Dailymotion video link';
      }
      
      // Twitch
      if (uri.host.contains('twitch.tv')) {
        return 'Twitch video link';
      }
      
      // Direct file
      final path = uri.path.toLowerCase();
      if (path.endsWith('.mp4')) return 'MP4 video bestand';
      if (path.endsWith('.avi')) return 'AVI video bestand';
      if (path.endsWith('.mov')) return 'MOV video bestand';
      if (path.endsWith('.wmv')) return 'WMV video bestand';
      if (path.endsWith('.flv')) return 'FLV video bestand';
      if (path.endsWith('.webm')) return 'WebM video bestand';
      if (path.endsWith('.mkv')) return 'MKV video bestand';
      if (path.endsWith('.m4v')) return 'M4V video bestand';
      
      if (path.endsWith('.mp3')) return 'MP3 audio bestand';
      if (path.endsWith('.wav')) return 'WAV audio bestand';
      if (path.endsWith('.aac')) return 'AAC audio bestand';
      if (path.endsWith('.ogg')) return 'OGG audio bestand';
      if (path.endsWith('.flac')) return 'FLAC audio bestand';
      if (path.endsWith('.m4a')) return 'M4A audio bestand';
      
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'JPEG afbeelding';
      if (path.endsWith('.png')) return 'PNG afbeelding';
      if (path.endsWith('.gif')) return 'GIF afbeelding';
      if (path.endsWith('.bmp')) return 'BMP afbeelding';
      if (path.endsWith('.webp')) return 'WebP afbeelding';
      if (path.endsWith('.svg')) return 'SVG afbeelding';
      
      // Generic
      return 'Media link naar ${uri.host}';
    } catch (e) {
      return 'Media link';
    }
  }
}

/// Information about a text field
class TextFieldInfo {
  final String label;
  final String hint;
  final String value;
  final String type;
  final bool isRequired;
  final bool isPassword;

  const TextFieldInfo({
    required this.label,
    required this.hint,
    required this.value,
    required this.type,
    required this.isRequired,
    required this.isPassword,
  });

  @override
  String toString() {
    return 'TextFieldInfo(label: $label, hint: $hint, value: $value, type: $type, isRequired: $isRequired, isPassword: $isPassword)';
  }
}
