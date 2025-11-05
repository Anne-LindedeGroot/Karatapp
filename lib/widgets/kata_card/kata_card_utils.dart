import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/kata_model.dart';
import '../../providers/accessibility_provider.dart';

class KataCardUtils {
  /// Always return the full description - no truncation
  static String getTruncatedDescription(String description) {
    return description;
  }

  /// Always show full description, so no toggle button needed
  static bool shouldShowToggleButton(String description) {
    return false;
  }

  /// Speak kata content using TTS
  static Future<void> speakKataContent(BuildContext context, WidgetRef ref, Kata kata) async {
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      final skipGeneralInfo = ref.read(skipGeneralInfoInTTSProvider);
      final content = StringBuffer();

      // Always include kata name
      content.write('Kata: ${kata.name}. ');

      // Always include style (this is important kata information)
      if (kata.style.isNotEmpty && kata.style != 'Unknown') {
        content.write('Stijl: ${kata.style}. ');
      }

      // Handle description based on skip setting
      if (kata.description.isNotEmpty) {
        if (skipGeneralInfo) {
          // Only include "Kata uitleg:" section, skip general information
          final descriptionParts = kata.description.split('\n');
          final kataUitlegParts = <String>[];
          bool foundKataUitleg = false;

          for (final part in descriptionParts) {
            if (part.toLowerCase().contains('kata uitleg:')) {
              foundKataUitleg = true;
              kataUitlegParts.add(part);
            } else if (foundKataUitleg) {
              // Add subsequent paragraphs to kata uitleg section
              kataUitlegParts.add(part);
            }
          }

          if (foundKataUitleg) {
            content.write('${kataUitlegParts.join(' ')}. ');
          }
        } else {
          // Include full description
          content.write('Beschrijving: ${kata.description}. ');
        }
      }

      // Always include media information (this is specific content, not general info)
      if (kata.imageUrls?.isNotEmpty == true) {
        content.write('Deze kata heeft ${kata.imageUrls?.length} afbeeldingen. ');
      }

      if (kata.videoUrls?.isNotEmpty == true) {
        content.write('Deze kata heeft ${kata.videoUrls?.length} video\'s. ');
      }

      await accessibilityNotifier.speak(content.toString());
    } catch (e) {
      debugPrint('Error speaking kata content: $e');
    }
  }

  /// Simplified error message for media loading errors
  static String getSimplifiedErrorMessage(String error) {
    if (error.contains('bucket not found')) {
      return 'Storage bucket not configured';
    } else if (error.contains('access denied') || error.contains('Unauthorized')) {
      return 'Access denied - check permissions';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Network connection issue';
    } else if (error.contains('timeout')) {
      return 'Request timed out';
    } else {
      return 'Unknown error occurred';
    }
  }
}
