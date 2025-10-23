import 'package:flutter/material.dart';

/// TTS Fallback Content Generator - Generates contextual fallback content
class TTSFallbackContentGenerator {
  /// Generate contextual fallback content based on current screen context
  static String generateContextualFallbackContent(BuildContext context) {
    try {
      if (!context.mounted) {
        return 'Pagina niet beschikbaar.';
      }
      
      final route = ModalRoute.of(context);
      if (route != null) {
        final routeName = route.settings.name ?? 'Unknown';
        return _generateFallbackContentBasedOnRoute(routeName);
      }
      
      return 'Pagina geladen.';
    } catch (e) {
      debugPrint('TTS: Error generating contextual fallback content: $e');
      return 'Pagina geladen.';
    }
  }

  /// Generate helpful fallback content based on page type
  static String _generateFallbackContentBasedOnRoute(String routeName) {
    switch (routeName) {
      case '/':
        return 'Welkom op de hoofdpagina. Hier kun je alle kata\'s bekijken en beheren.';
      case '/profile':
        return 'Dit is je profiel pagina. Hier kun je je account instellingen beheren.';
      case '/forum':
        return 'Dit is het forum. Hier kun je discussies bekijken en nieuwe berichten plaatsen.';
      case '/login':
        return 'Dit is de inlog pagina. Voer je gegevens in om in te loggen.';
      case '/register':
        return 'Dit is de registratie pagina. Vul het formulier in om een account aan te maken.';
      case '/favorites':
        return 'Dit zijn je favoriete kata\'s. Hier kun je je opgeslagen kata\'s bekijken.';
      case '/user-management':
        return 'Dit is de gebruikersbeheer pagina. Hier kun je gebruikers beheren.';
      case '/avatar-selection':
        return 'Dit is de avatar selectie pagina. Kies een avatar voor je profiel.';
      case '/accessibility':
        return 'Dit zijn de toegankelijkheidsinstellingen. Pas de instellingen aan voor een betere ervaring.';
      default:
        return 'Pagina geladen. Gebruik de navigatie om door de app te bladeren.';
    }
  }

  /// Generate fallback content for specific screen types
  static String generateFallbackForScreenType(String screenType) {
    switch (screenType.toLowerCase()) {
      case 'home':
        return 'Welkom op de hoofdpagina. Hier kun je alle kata\'s bekijken en beheren.';
      case 'profile':
        return 'Dit is je profiel pagina. Hier kun je je account instellingen beheren.';
      case 'forum':
        return 'Dit is het forum. Hier kun je discussies bekijken en nieuwe berichten plaatsen.';
      case 'auth':
        return 'Dit is een authenticatie pagina. Voer je gegevens in om door te gaan.';
      case 'form':
        return 'Dit is een formulier pagina. Vul de velden in om door te gaan.';
      case 'overlay':
        return 'Er is een dialoog of menu geopend.';
      default:
        return 'Pagina geladen. Gebruik de navigatie om door de app te bladeren.';
    }
  }

  /// Generate fallback content for empty screens
  static String generateEmptyScreenFallback(BuildContext context) {
    try {
      if (!context.mounted) {
        return 'Pagina niet beschikbaar.';
      }
      
      // Check if there are any loading indicators
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold != null) {
        return 'Pagina wordt geladen. Even geduld.';
      }
      
      return 'Pagina geladen. Er is geen zichtbare inhoud gevonden.';
    } catch (e) {
      debugPrint('TTS: Error generating empty screen fallback: $e');
      return 'Pagina geladen.';
    }
  }

  /// Generate fallback content for error states
  static String generateErrorFallback(String errorType) {
    switch (errorType.toLowerCase()) {
      case 'network':
        return 'Er is een netwerkprobleem. Controleer je internetverbinding.';
      case 'permission':
        return 'Je hebt geen toestemming voor deze actie.';
      case 'not_found':
        return 'De gevraagde inhoud is niet gevonden.';
      case 'timeout':
        return 'De actie duurt te lang. Probeer het opnieuw.';
      default:
        return 'Er is een probleem opgetreden. Probeer het opnieuw.';
    }
  }
}
