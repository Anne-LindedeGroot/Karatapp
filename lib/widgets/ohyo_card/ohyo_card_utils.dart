import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ohyo_model.dart';
import '../../providers/accessibility_provider.dart';

class OhyoCardUtils {
  /// Always return the full description - no truncation
  static String getTruncatedDescription(String description) {
    return description;
  }

  /// Always show full description, so no toggle button needed
  static bool shouldShowToggleButton(String description) {
    return false;
  }

  /// Speak ohyo content using TTS
  static Future<void> speakOhyoContent(BuildContext context, WidgetRef ref, Ohyo ohyo) async {
    try {
      final accessibilityState = ref.read(accessibilityNotifierProvider);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

      // Only speak if TTS is enabled
      if (!accessibilityState.isTextToSpeechEnabled) {
        debugPrint('OhyoCardUtils TTS: TTS is disabled, not speaking ohyo content');
        return;
      }

      final skipGeneralInfo = ref.read(skipGeneralInfoInTTSOhyoProvider);
      final content = StringBuffer();

      // Always include ohyo name
      content.write('Ohyo: ${ohyo.name}. ');

      // Always include style (this is important ohyo information)
      content.write('Stijl: ${ohyo.style}. ');

      // Handle description based on skip setting
      if (ohyo.description.isNotEmpty) {
        if (skipGeneralInfo) {
          // Only include "Ohyo uitleg:" section, skip general information
          final descriptionParts = ohyo.description.split('\n');
          final ohyoUitlegParts = <String>[];
          bool foundOhyoUitleg = false;

          for (final part in descriptionParts) {
            if (part.toLowerCase().contains('ohyo uitleg:')) {
              foundOhyoUitleg = true;
              ohyoUitlegParts.add(part);
            } else if (foundOhyoUitleg) {
              // Add subsequent paragraphs to ohyo uitleg section
              ohyoUitlegParts.add(part);
            }
          }

          if (foundOhyoUitleg) {
            content.write('${ohyoUitlegParts.join(' ')}. ');
          }
        } else {
          // Include full description
          content.write('Beschrijving: ${ohyo.description}. ');
        }
      }

      // Always include media information (this is specific content, not general info)
      if (ohyo.imageUrls?.isNotEmpty == true) {
        content.write('Deze ohyo heeft ${ohyo.imageUrls?.length} afbeeldingen. ');
      }

      if (ohyo.videoUrls?.isNotEmpty == true) {
        content.write('Deze ohyo heeft ${ohyo.videoUrls?.length} video\'s. ');
      }

      await accessibilityNotifier.speak(content.toString());
    } catch (e) {
      debugPrint('Error speaking ohyo content: $e');
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
