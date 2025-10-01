import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';
import '../services/role_service.dart';
import 'universal_tts_service.dart';

/// Context-aware TTS service that provides specific reading functionality for different screens and components
class ContextAwarePageTTSService {
  static final ContextAwarePageTTSService _instance = ContextAwarePageTTSService._internal();
  factory ContextAwarePageTTSService() => _instance;
  ContextAwarePageTTSService._internal();

  /// Read profile screen content including textarea
  static Future<void> readProfileScreen(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final content = _extractProfileContent(context, ref);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Je bent nu op profiel scherm. $content');
    } catch (e) {
      debugPrint('Error reading profile screen: $e');
    }
  }

  /// Read kata form content (add/edit)
  static Future<void> readKataForm(BuildContext context, WidgetRef ref, {bool isEdit = false}) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final content = _extractKataFormContent(context);
      final formType = isEdit ? 'Kata bewerken' : 'Nieuwe kata aanmaken';
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('$formType formulier. $content');
    } catch (e) {
      debugPrint('Error reading kata form: $e');
    }
  }

  /// Read kata form description dialog content
  static Future<void> readKataFormDescriptionDialog(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      
      // Stop any existing TTS before starting dialog reading
      await accessibilityNotifier.stopSpeaking();
      
      // Small delay to ensure previous TTS is fully stopped
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Check if context is still mounted after async operation
      if (!context.mounted) return;
      
      final content = _extractKataDescriptionDialogContent(context);
      await accessibilityNotifier.speak(content);
    } catch (e) {
      debugPrint('Error reading kata description dialog: $e');
    }
  }

  /// Read kata comments section
  static Future<void> readKataComments(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final content = _extractCommentsContent(context);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Kata reacties sectie. $content');
    } catch (e) {
      debugPrint('Error reading kata comments: $e');
    }
  }

  /// Read favorites screen content based on current tab
  static Future<void> readFavoritesScreen(BuildContext context, WidgetRef ref, String currentTab) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final content = _extractFavoritesContent(context, currentTab);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Favorieten pagina, $currentTab tab. $content');
    } catch (e) {
      debugPrint('Error reading favorites screen: $e');
    }
  }

  /// Read forum home page posts
  static Future<void> readForumHomePage(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final content = _extractForumPostsContent(context);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Forum hoofdpagina. $content');
    } catch (e) {
      debugPrint('Error reading forum home page: $e');
    }
  }

  /// Read forum post form
  static Future<void> readForumPostForm(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final content = _extractFormContent(context);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Nieuw forum bericht formulier. $content');
    } catch (e) {
      debugPrint('Error reading forum post form: $e');
    }
  }

  /// Read forum post detail with comments
  static Future<void> readForumPostDetail(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final content = _extractForumPostDetailContent(context);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Forum bericht details. $content');
    } catch (e) {
      debugPrint('Error reading forum post detail: $e');
    }
  }

  /// Read user management screen with privacy warning
  static Future<void> readUserManagementScreen(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      
      // First provide privacy warning
      await accessibilityNotifier.speak(
        'Waarschuwing: Je gaat gebruikersbeheer informatie beluisteren. '
        'Deze bevat gevoelige persoonlijke gegevens zoals e-mailadressen en namen. '
        'Zorg ervoor dat je je volume laag hebt staan of gebruik koptelefoon of oordopjes '
        'om privacy te waarborgen, vooral in oenable ruimtes.'
      );
      
      // Wait a moment before continuing
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Check if context is still mounted after async operation
      if (!context.mounted) return;
      
      final content = await _extractUserManagementContentFromService(context, ref);
      await accessibilityNotifier.speak('Gebruikersbeheer pagina. $content');
    } catch (e) {
      debugPrint('Error reading user management screen: $e');
    }
  }

  /// Read delete popup content
  static Future<void> readDeletePopup(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final content = _extractDialogContent(context);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Verwijder bevestiging. $content');
    } catch (e) {
      debugPrint('Error reading delete popup: $e');
    }
  }

  /// Read clean images popup content
  static Future<void> readCleanImagesPopup(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      
      // Stop any existing TTS before starting popup reading
      await accessibilityNotifier.stopSpeaking();
      
      // Small delay to ensure previous TTS is fully stopped
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Check if context is still mounted after async operation
      if (!context.mounted) return;
      
      final content = _extractCleanImagesPopupContent(context);
      await accessibilityNotifier.speak(content);
    } catch (e) {
      debugPrint('Error reading clean images popup: $e');
    }
  }

  /// Read logout popup content
  static Future<void> readLogoutPopup(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      
      // Stop any existing TTS before starting popup reading
      await accessibilityNotifier.stopSpeaking();
      
      // Small delay to ensure previous TTS is fully stopped
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Check if context is still mounted after async operation
      if (!context.mounted) return;
      
      final content = _extractLogoutPopupContent(context);
      await accessibilityNotifier.speak(content);
    } catch (e) {
      debugPrint('Error reading logout popup: $e');
    }
  }

  /// Read app bar and home page content (including katas)
  static Future<void> readAppBarAndHomePage(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final content = _extractHomePageWithAppBarContent(context);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Hoofdpagina met app balk. $content');
    } catch (e) {
      debugPrint('Error reading app bar and home page: $e');
    }
  }

  /// Read menu content
  static Future<void> readMenuContent(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final content = _extractMenuContent(context);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Menu inhoud. $content');
    } catch (e) {
      debugPrint('Error reading menu content: $e');
    }
  }

  // Private helper methods for content extraction

  static String _extractProfileContent(BuildContext context, WidgetRef ref) {
    final StringBuffer content = StringBuffer();
    
    try {
      // Get user data from provider
      final authState = ref.read(authNotifierProvider);
      final currentUser = authState.user;
      
      content.write('Gebruikersprofiel sectie. ');
      
      // Read email
      if (currentUser?.email != null) {
        content.write('E-mail adres: ${currentUser!.email}. ');
      }
      
      // Read role information
      try {
        final userRole = ref.read(currentUserRoleProvider).value;
        if (userRole != null) {
          content.write('Rol: ${userRole.displayName}. ${userRole.description}. ');
        }
      } catch (e) {
        content.write('Rol: wordt geladen. ');
      }
      
      // Read name field content
      final nameValue = currentUser?.userMetadata?['full_name']?.toString();
      if (nameValue != null && nameValue.isNotEmpty) {
        content.write('Volledige naam: $nameValue. ');
      } else {
        content.write('Volledige naam veld is leeg. Je kunt hier je naam invoeren. ');
      }
      
      content.write('Er is een knop beschikbaar om je naam bij te werken. ');
      content.write('Je kunt ook je avatar wijzigen door erop te tikken. ');
      
      // Add accessibility settings section
      content.write('Toegankelijkheid sectie. ');
      content.write('Spraakknop weergeven schakelaar beschikbaar. ');
      content.write('Deze schakelaar bepaalt of de spraakknop op alle schermen wordt getoond. ');
      
      // Extract any additional text from the screen
      try {
        final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
        if (scaffold?.body != null) {
          final bodyText = UniversalTTSService.extractAllTextFromWidget(scaffold!.body!);
          final lines = bodyText.split('\n').where((line) => line.trim().isNotEmpty).toList();
          
          // Look for any additional content we might have missed
          for (final line in lines) {
            final trimmedLine = line.trim();
            if (trimmedLine.length > 10 && 
                !trimmedLine.contains('Gebruikersprofiel') &&
                !trimmedLine.contains('E-mail') &&
                !trimmedLine.contains('Rol') &&
                !trimmedLine.contains('Volledige naam') &&
                !trimmedLine.contains('Toegankelijkheid') &&
                !trimmedLine.contains('Spraakknop') &&
                !trimmedLine.contains('knop') &&
                !trimmedLine.contains('invoerveld')) {
              content.write('$trimmedLine. ');
            }
          }
        }
      } catch (e) {
        debugPrint('Error extracting additional profile content: $e');
      }
      
    } catch (e) {
      debugPrint('Error extracting profile content: $e');
      content.write('Profiel pagina geladen. ');
    }
    
    return content.toString();
  }

  static String _extractFormContent(BuildContext context) {
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    if (scaffold?.body == null) return 'Geen formulier inhoud gevonden.';

    final bodyText = UniversalTTSService.extractAllTextFromWidget(scaffold!.body!);
    
    final StringBuffer content = StringBuffer();
    
    // Check if this is a forum post form
    if (bodyText.contains('Nieuw Bericht Maken') || bodyText.contains('Categorie')) {
      return _extractForumPostFormContent(context);
    }
    
    // Look for form elements
    final lines = bodyText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    int fieldCount = 0;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.contains('invoerveld') || 
          trimmedLine.contains('Titel') || 
          trimmedLine.contains('Beschrijving') ||
          trimmedLine.contains('Naam') ||
          trimmedLine.contains('Email') ||
          trimmedLine.length > 20) {
        fieldCount++;
        content.write('Veld $fieldCount: $trimmedLine. ');
      }
    }
    
    if (fieldCount == 0) {
      content.write('Formulier met verschillende invoervelden. ');
      content.write(bodyText.length > 100 ? '${bodyText.substring(0, 100)}...' : bodyText);
    }
    
    return content.toString().isNotEmpty ? content.toString() : 'Formulier geladen.';
  }

  /// Extract content from forum post form
  static String _extractForumPostFormContent(BuildContext context) {
    final StringBuffer content = StringBuffer();
    
    try {
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold?.body != null) {
        final bodyText = UniversalTTSService.extractAllTextFromWidget(scaffold!.body!);
        
        content.write('Nieuw forum bericht formulier. ');
        
        // Extract form sections
        if (bodyText.contains('Categorie')) {
          content.write('Categorie selectie sectie. ');
          content.write('Beschikbare categorieën: Algemene discussies, Kata aanvragen, Technieken, Evenementen, Feedback. ');
          content.write('Selecteer een categorie door erop te tikken. ');
        }
        
        if (bodyText.contains('Titel')) {
          content.write('Titel invoerveld - voer een beschrijvende titel in voor je bericht. ');
        }
        
        if (bodyText.contains('Inhoud')) {
          content.write('Inhoud invoerveld - schrijf hier de inhoud van je bericht. ');
        }
        
        // Try to extract current text content from textareas
        final textareaContent = _extractTextareaContent(context);
        if (textareaContent.isNotEmpty) {
          content.write(textareaContent);
        }
        
        // Add form completion information
        content.write('Vul alle velden in en tik op de publiceren knop om je bericht te plaatsen. ');
      }
    } catch (e) {
      debugPrint('Error extracting forum post form content: $e');
      content.write('Forum bericht formulier geladen. ');
    }
    
    return content.toString().isNotEmpty ? content.toString() : 'Forum bericht formulier geladen.';
  }

  /// Extract kata form content specifically for the add kata dialog
  static String _extractKataFormContent(BuildContext context) {
    final StringBuffer content = StringBuffer();
    
    // Look for the dialog content directly
    final dialog = context.findAncestorWidgetOfExactType<AlertDialog>();
    if (dialog != null) {
      final dialogText = UniversalTTSService.extractAllTextFromWidget(dialog);
      
      content.write('Nieuw kata toevoegen formulier. ');
      
      // Extract form fields systematically
      if (dialogText.contains('Kata Naam')) {
        content.write('Kata Naam invoerveld - voer de naam van je kata in. ');
      }
      
      if (dialogText.contains('Stijl')) {
        content.write('Stijl invoerveld - voer de karate stijl in, bijvoorbeeld Wado Ryu. ');
      }
      
      if (dialogText.contains('Beschrijving')) {
        content.write('Beschrijving invoerveld - voer een beschrijving van je kata in. ');
      }
      
      // Image section
      if (dialogText.contains('Afbeeldingen')) {
        content.write('Afbeeldingen sectie - voeg foto\'s van je kata toe. ');
        content.write('Galerij knop - selecteer afbeeldingen uit je galerij. ');
        content.write('Camera knop - maak een nieuwe foto met je camera. ');
        content.write('Je kunt afbeeldingen herordenen door ze vast te houden en te slepen. ');
      }
      
      // Video section
      if (dialogText.contains('Video URLs')) {
        content.write('Video URLs sectie - voeg video links toe. ');
        content.write('Voer video URL in invoerveld - bijvoorbeeld YouTube links. ');
      }
      
      // Action buttons
      if (dialogText.contains('Annuleren')) {
        content.write('Annuleren knop - sluit het formulier zonder op te slaan. ');
      }
      
      if (dialogText.contains('Kata Toevoegen')) {
        content.write('Kata Toevoegen knop - sla je kata op en voeg het toe aan de collectie. ');
      }
      
      return content.toString();
    }
    
    // Enhanced form extraction for full-screen kata forms
    return _extractFullScreenKataFormContent(context);
  }

  /// Extract content from full-screen kata forms (create/edit kata screens)
  static String _extractFullScreenKataFormContent(BuildContext context) {
    final StringBuffer content = StringBuffer();
    
    try {
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold?.body != null) {
        final bodyText = UniversalTTSService.extractAllTextFromWidget(scaffold!.body!);
        
        content.write('Kata formulier. ');
        
        // Extract form sections
        if (bodyText.contains('Kata Informatie')) {
          content.write('Kata Informatie sectie. ');
        }
        
        if (bodyText.contains('Kata Naam')) {
          content.write('Kata Naam invoerveld - voer de naam van je kata in. ');
        }
        
        if (bodyText.contains('Stijl')) {
          content.write('Stijl invoerveld - voer de karate stijl in. ');
        }
        
        if (bodyText.contains('Beschrijving')) {
          content.write('Beschrijving invoerveld - tik om beschrijving toe te voegen of te bewerken. ');
        }
        
        if (bodyText.contains('Privé Kata')) {
          content.write('Privé Kata schakelaar - maak je kata privé of openbaar. ');
        }
        
        if (bodyText.contains('Afbeeldingen')) {
          content.write('Afbeeldingen sectie - voeg foto\'s van je kata toe. ');
        }
        
        if (bodyText.contains('Video')) {
          content.write('Video sectie - voeg video links toe. ');
        }
        
        // Try to extract current text content from textareas
        final textareaContent = _extractTextareaContent(context);
        if (textareaContent.isNotEmpty) {
          content.write(textareaContent);
        }
        
        // Add form completion information
        content.write('Vul alle verplichte velden in en tik op de opslaan knop om je kata op te slaan. ');
      }
    } catch (e) {
      debugPrint('Error extracting full-screen kata form content: $e');
      content.write('Kata formulier geladen. ');
    }
    
    return content.toString().isNotEmpty ? content.toString() : 'Kata formulier geladen.';
  }


  /// Extract content from textarea/TextFormField controllers
  static String _extractTextareaContent(BuildContext context) {
    final StringBuffer content = StringBuffer();
    
    try {
      // Try to find TextFormField widgets and extract their content
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold?.body != null) {
        final bodyText = UniversalTTSService.extractAllTextFromWidget(scaffold!.body!);
        
        // Look for text content that might be from textareas
        final lines = bodyText.split('\n').where((line) => line.trim().isNotEmpty).toList();
        
        for (final line in lines) {
          final trimmedLine = line.trim();
          // Look for content that appears to be user input (longer text, not UI labels)
          if (trimmedLine.length > 20 && 
              !trimmedLine.contains('invoerveld') && 
              !trimmedLine.contains('knop') &&
              !trimmedLine.contains('Tik om') &&
              !trimmedLine.contains('Voer') &&
              !trimmedLine.contains('Kata Naam') &&
              !trimmedLine.contains('Stijl') &&
              !trimmedLine.contains('Beschrijving')) {
            content.write('Huidige tekst: $trimmedLine. ');
          }
        }
      }
      
      if (content.isEmpty) {
        content.write('Tekst invoerveld beschikbaar voor beschrijving. ');
      }
    } catch (e) {
      debugPrint('Error extracting textarea content: $e');
      content.write('Tekst invoerveld beschikbaar voor beschrijving. ');
    }
    
    return content.toString();
  }

  static String _extractCommentsContent(BuildContext context) {
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    if (scaffold?.body == null) return 'Geen reacties gevonden.';

    final bodyText = UniversalTTSService.extractAllTextFromWidget(scaffold!.body!);
    
    final StringBuffer content = StringBuffer();
    
    // Look for comment-like content
    final lines = bodyText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    int commentCount = 0;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.length > 15 && !trimmedLine.contains('knop') && !trimmedLine.contains('invoerveld')) {
        commentCount++;
        if (commentCount <= 5) { // Limit to first 5 comments
          content.write('Reactie $commentCount: $trimmedLine. ');
        }
      }
    }
    
    if (commentCount > 5) {
      content.write('En ${commentCount - 5} meer reacties. ');
    }
    
    if (commentCount == 0) {
      content.write('Nog geen reacties geplaatst. ');
    }
    
    return content.toString().isNotEmpty ? content.toString() : 'Reacties sectie geladen.';
  }

  static String _extractFavoritesContent(BuildContext context, String currentTab) {
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    if (scaffold?.body == null) return 'Geen favorieten gevonden.';

    final bodyText = UniversalTTSService.extractAllTextFromWidget(scaffold!.body!);
    
    final StringBuffer content = StringBuffer();
    content.write('Je bekijkt nu de $currentTab tab. ');
    
    // Count items
    final lines = bodyText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    int itemCount = 0;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.length > 10 && !trimmedLine.contains('tab') && !trimmedLine.contains('knop')) {
        itemCount++;
        if (itemCount <= 3) { // Limit to first 3 items
          content.write('Item $itemCount: $trimmedLine. ');
        }
      }
    }
    
    if (itemCount > 3) {
      content.write('En ${itemCount - 3} meer items. ');
    }
    
    if (itemCount == 0) {
      content.write('Geen items gevonden in deze tab. ');
    }
    
    return content.toString();
  }

  static String _extractForumPostsContent(BuildContext context) {
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    if (scaffold?.body == null) return 'Geen forum berichten gevonden.';

    final bodyText = UniversalTTSService.extractAllTextFromWidget(scaffold!.body!);
    
    final StringBuffer content = StringBuffer();
    
    // Look for post-like content with better filtering
    final lines = bodyText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    int postCount = 0;
    
    content.write('Forum berichten overzicht. ');
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      // Better filtering for actual post content
      if (trimmedLine.length > 10 && 
          !trimmedLine.contains('knop') && 
          !trimmedLine.contains('invoerveld') &&
          !trimmedLine.contains('Zoek berichten') &&
          !trimmedLine.contains('Berichten verversen') &&
          !trimmedLine.contains('Nieuw bericht maken') &&
          !trimmedLine.contains('Alle') &&
          !trimmedLine.contains('Algemene discussies') &&
          !trimmedLine.contains('Kata aanvragen') &&
          !trimmedLine.contains('Technieken') &&
          !trimmedLine.contains('Evenementen') &&
          !trimmedLine.contains('Feedback') &&
          !trimmedLine.contains('d geleden') &&
          !trimmedLine.contains('u geleden') &&
          !trimmedLine.contains('m geleden') &&
          !trimmedLine.contains('Zojuist') &&
          !trimmedLine.contains('Geen berichten gevonden')) {
        postCount++;
        if (postCount <= 5) { // Increased limit to 5 posts
          content.write('Bericht $postCount: $trimmedLine. ');
        }
      }
    }
    
    if (postCount > 5) {
      content.write('En ${postCount - 5} meer berichten beschikbaar. ');
    }
    
    if (postCount == 0) {
      content.write('Nog geen berichten geplaatst in het forum. ');
    }
    
    // Add forum navigation information
    content.write('Je kunt op een bericht tikken om de details te bekijken. ');
    content.write('Gebruik de zoekbalk om specifieke berichten te vinden. ');
    content.write('Filter berichten op categorie met de chips bovenaan. ');
    
    return content.toString().isNotEmpty ? content.toString() : 'Forum berichten geladen.';
  }

  static String _extractForumPostDetailContent(BuildContext context) {
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    if (scaffold?.body == null) return 'Geen bericht details gevonden.';

    final bodyText = UniversalTTSService.extractAllTextFromWidget(scaffold!.body!);
    
    final StringBuffer content = StringBuffer();
    
    // Extract post content and comments
    final lines = bodyText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    
    if (lines.isNotEmpty) {
      // First significant line is likely the post title/content
      content.write('Forum bericht inhoud: ${lines.first}. ');
      
      // Look for comments section
      content.write('Reacties sectie: ');
      
      // Look for comments
      int commentCount = 0;
      for (int i = 1; i < lines.length; i++) {
        final trimmedLine = lines[i].trim();
        if (trimmedLine.length > 15 && !trimmedLine.contains('knop') && !trimmedLine.contains('invoerveld')) {
          commentCount++;
          if (commentCount <= 5) { // Increased limit for comments
            content.write('Reactie $commentCount: $trimmedLine. ');
          }
        }
      }
      
      if (commentCount > 5) {
        content.write('En ${commentCount - 5} meer reacties. ');
      }
      
      if (commentCount == 0) {
        content.write('Nog geen reacties geplaatst op dit bericht. ');
      }
      
      // Add information about comment input field
      content.write('Je kunt een nieuwe reactie plaatsen door te tikken op het reactie invoerveld. ');
    }
    
    return content.toString().isNotEmpty ? content.toString() : 'Forum bericht details geladen.';
  }

  /// Extract user management content directly from RoleService data
  static Future<String> _extractUserManagementContentFromService(BuildContext context, WidgetRef ref) async {
    final StringBuffer content = StringBuffer();
    
    try {
      // Get current user role to provide context
      final userRole = ref.read(currentUserRoleProvider).value;
      
      content.write('Gebruikersrollenbeheer. ');
      
      if (userRole != null) {
        content.write('Je huidige rol is ${userRole.displayName}. ');
        
        if (userRole == UserRole.host) {
          content.write('Als host kun je gebruikersrollen wijzigen en gebruikers dempen. ');
        } else if (userRole == UserRole.mediator) {
          content.write('Als moderator kun je gebruikers dempen maar geen rollen wijzigen. ');
        }
      }
      
      content.write('Beschikbare functies: ');
      content.write('Beheer gebruikersrollen - wijzig rollen van gebruikers tussen gebruiker, moderator en host. ');
      content.write('Demp gebruikers - tijdelijk dempen van gebruikers voor verschillende periodes. ');
      content.write('Bekijk dempgeschiedenis - zie eerdere dempingen van gebruikers. ');
      
      // Get user data directly from RoleService
      try {
        final roleService = RoleService();
        final users = await roleService.getAllUsersWithRoles();
        
        if (users.isNotEmpty) {
          content.write('Er zijn ${users.length} gebruikers in het systeem. ');
          
          // Count users by role
          int hostCount = 0;
          int moderatorCount = 0;
          int regularUserCount = 0;
          
          for (final user in users) {
            final role = user['role'] as String? ?? 'user';
            switch (role) {
              case 'host':
                hostCount++;
                break;
              case 'mediator':
                moderatorCount++;
                break;
              default:
                regularUserCount++;
                break;
            }
          }
          
          if (hostCount > 0) content.write('$hostCount hosts, ');
          if (moderatorCount > 0) content.write('$moderatorCount moderators, ');
          if (regularUserCount > 0) content.write('$regularUserCount gewone gebruikers. ');
          
          // Read individual user details (limit to first 5 users for brevity)
          content.write('Gebruikersdetails: ');
          final currentUser = ref.read(authUserProvider);
          
          for (int i = 0; i < users.length && i < 5; i++) {
            final user = users[i];
            final userId = user['id'] as String;
            final email = user['email'] as String? ?? 'Geen email';
            final fullName = user['full_name'] as String? ?? 'Geen naam';
            final roleString = user['role'] as String? ?? 'user';
            
            final role = UserRole.values.firstWhere(
              (r) => r.value == roleString,
              orElse: () => UserRole.user,
            );
            
            final isCurrentUser = userId == currentUser?.id;
            final userDescription = isCurrentUser ? 'Jij bent' : 'Gebruiker ${i + 1} is';
            
            content.write('$userDescription $fullName met e-mail $email en heeft rol ${role.displayName}. ');
          }
          
          if (users.length > 5) {
            content.write('En ${users.length - 5} meer gebruikers. ');
          }
        } else {
          content.write('Geen gebruikers gevonden in het systeem. ');
        }
      } catch (e) {
        debugPrint('Error fetching user data from RoleService: $e');
        content.write('Kon gebruikersgegevens niet ophalen van de server. ');
      }
      
    } catch (e) {
      debugPrint('Error extracting user management content: $e');
      content.write('Gebruikersbeheer interface geladen. ');
    }
    
    return content.toString().isNotEmpty ? content.toString() : 'Gebruikersbeheer pagina geladen.';
  }


  static String _extractDialogContent(BuildContext context) {
    // Look for dialog content
    final dialog = context.findAncestorWidgetOfExactType<Dialog>() ?? 
                   context.findAncestorWidgetOfExactType<AlertDialog>();
    
    if (dialog != null) {
      final dialogText = UniversalTTSService.extractAllTextFromWidget(dialog);
      return dialogText.isNotEmpty ? dialogText : 'Bevestiging venster geopend.';
    }
    
    // Fallback to looking for any modal content
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    if (scaffold?.body != null) {
      final bodyText = UniversalTTSService.extractAllTextFromWidget(scaffold!.body!);
      final lines = bodyText.split('\n').where((line) => line.trim().isNotEmpty).take(3).toList();
      return lines.join('. ');
    }
    
    return 'Popup venster geopend.';
  }

  static String _extractHomePageWithAppBarContent(BuildContext context) {
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    if (scaffold == null) return 'Hoofdpagina geladen.';

    final StringBuffer content = StringBuffer();
    
    // Extract AppBar content
    if (scaffold.appBar != null) {
      final appBarText = UniversalTTSService.extractAllTextFromWidget(scaffold.appBar!);
      if (appBarText.isNotEmpty) {
        content.write('App balk: $appBarText. ');
      }
    }
    
    // Extract main content (katas)
    if (scaffold.body != null) {
      final bodyText = UniversalTTSService.extractAllTextFromWidget(scaffold.body!);
      
      // Look for kata-like content
      final lines = bodyText.split('\n').where((line) => line.trim().isNotEmpty).toList();
      int kataCount = 0;
      
      content.write('Hoofdinhoud: ');
      
      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.length > 10 && !trimmedLine.contains('knop') && !trimmedLine.contains('invoerveld')) {
          kataCount++;
          if (kataCount <= 5) { // Increased limit for katas
            content.write('Kata $kataCount: $trimmedLine. ');
          }
        }
      }
      
      if (kataCount > 5) {
        content.write('En ${kataCount - 5} meer kata\'s beschikbaar. ');
      }
      
      if (kataCount == 0) {
        content.write('Kata overzicht geladen. ');
      }
      
      // Add information about search functionality
      content.write('Je kunt kata\'s zoeken met de zoekbalk bovenaan. ');
      content.write('Tik op een kata om de details te bekijken. ');
    }
    
    return content.toString().isNotEmpty ? content.toString() : 'Hoofdpagina met app balk geladen.';
  }

  static String _extractMenuContent(BuildContext context) {
    final StringBuffer content = StringBuffer();
    
    // Since this is a popup menu, we'll provide a comprehensive description
    content.write('Gebruikersmenu geopend. ');
    content.write('Beschikbare opties: ');
    content.write('Profiel - ga naar je profiel pagina om je gegevens te bekijken en te bewerken. ');
    content.write('Mijn Favorieten - bekijk je opgeslagen favoriete kata\'s en forum berichten. ');
    content.write('Gebruikersbeheer - beheer gebruikers en rollen, alleen beschikbaar voor beheerders. ');
    content.write('Afbeeldingen opruimen - verwijder verweesde afbeeldingen uit de opslag om ruimte vrij te maken. ');
    content.write('Thema instellingen - kies tussen licht, donker of systeem thema voor de interface. ');
    content.write('Hoog contrast - schakel hoog contrast modus in of uit voor betere zichtbaarheid van tekst en elementen. ');
    content.write('Uitloggen - log uit van de applicatie en keer terug naar het inlogscherm. ');
    content.write('Tik op een optie om deze te selecteren, of tik buiten het menu om het te sluiten. ');
    
    return content.toString();
  }

  static String _extractLogoutPopupContent(BuildContext context) {
    final StringBuffer content = StringBuffer();
    
    // Provide a comprehensive description of the logout popup
    content.write('Uitloggen bevestiging popup geopend. ');
    content.write('Titel: Uitloggen. ');
    content.write('Bericht: Weet je/u zeker dat je uit wilt loggen? ');
    content.write('Er zijn twee knoppen beschikbaar: ');
    content.write('Eerste knop: "Nee dankje makker!" - om het uitloggen te annuleren en in de app te blijven. ');
    content.write('Tweede knop: "Ja tuurlijk!" - om te bevestigen en uit te loggen van de applicatie. ');
    content.write('Kies "Nee dankje makker!" om te blijven, of "Ja tuurlijk!" om uit te loggen.');
    
    return content.toString();
  }

  static String _extractKataDescriptionDialogContent(BuildContext context) {
    final StringBuffer content = StringBuffer();
    
    // Read the full form content from the background scaffold, not just the dialog
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    if (scaffold?.body != null) {
      final bodyText = UniversalTTSService.extractAllTextFromWidget(scaffold!.body!);
      
      content.write('Nieuw kata toevoegen formulier. ');
      content.write('Titel: Nieuwe Kata Maken. ');
      
      // Look for form fields in a structured way
      if (bodyText.contains('Kata Naam')) {
        content.write('Kata Naam invoerveld. ');
      }
      
      if (bodyText.contains('Stijl')) {
        content.write('Stijl invoerveld. ');
      }
      
      if (bodyText.contains('Beschrijving')) {
        content.write('Beschrijving invoerveld. ');
      }
      
      if (bodyText.contains('Privé Kata')) {
        content.write('Privé Kata schakelaar. ');
      }
      
      // Image section
      if (bodyText.contains('Galerij')) {
        content.write('Afbeeldingen sectie. ');
        content.write('Galerij knop. ');
      }
      
      if (bodyText.contains('Camera')) {
        content.write('Camera knop. ');
      }
      
      // Video section
      if (bodyText.contains('Video')) {
        content.write('Video URLs sectie. ');
        content.write('Voer video URL in invoerveld. ');
      }
      
      // Bottom buttons
      if (bodyText.contains('Annuleren')) {
        content.write('Annuleren knop. ');
      }
      
      if (bodyText.contains('Kata Toevoegen') || bodyText.contains('Opslaan')) {
        content.write('Kata Toevoegen knop. ');
      }
      
      // Current dialog context
      content.write('Je bent nu in de beschrijving bewerken dialog. ');
      content.write('Voer hier de volledige beschrijving van je kata in. ');
      content.write('Tik op Opslaan om je beschrijving op te slaan en terug te gaan naar het formulier.');
    }
    
    if (content.length == 0) {
      content.write('Nieuw kata toevoegen formulier. ');
      content.write('Kata beschrijving bewerken dialog geopend. ');
      content.write('Voer hier je kata beschrijving in en tik op Opslaan.');
    }
    
    return content.toString();
  }

  static String _extractCleanImagesPopupContent(BuildContext context) {
    final StringBuffer content = StringBuffer();
    
    // Provide a comprehensive description of the clean images popup
    content.write('Afbeeldingen opruimen bevestiging popup geopend. ');
    content.write('Titel: Verweesde afbeeldingen opruimen? ');
    content.write('Bericht: Dit zal scannen naar en verwijderen van afbeeldingen die niet bij een bestaande kata horen. ');
    content.write('Dit omvat afbeeldingen in mappen zoals "0" of "temp_" die mogelijk zijn achtergebleven. ');
    content.write('Deze actie kan niet ongedaan worden gemaakt. ');
    content.write('Er zijn twee knoppen beschikbaar: ');
    content.write('Eerste knop: "Annuleren" - om het opruimen te annuleren en terug te gaan. ');
    content.write('Tweede knop: "Opruimen" - om te bevestigen en de verweesde afbeeldingen te verwijderen. ');
    content.write('Kies "Annuleren" om terug te gaan, of "Opruimen" om de afbeeldingen op te ruimen.');
    
    return content.toString();
  }

  /// Read theme settings content
  static Future<void> readThemeSettings(BuildContext context, WidgetRef ref, String settingType, String currentValue) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      String content;
      switch (settingType) {
        case 'theme':
          content = 'Thema instelling. Huidige instelling: $currentValue. '
                   'Beschikbare opties: Licht thema voor een heldere interface, '
                   'Donker thema voor een donkere interface, '
                   'Systeem thema om automatisch te wisselen tussen licht en donker.';
          break;
        case 'contrast':
          final isEnabled = currentValue == 'aan';
          content = 'Hoog contrast instelling. Huidige instelling: $currentValue. '
                   '${isEnabled ? "Hoog contrast is ingeschakeld voor betere zichtbaarheid." : "Hoog contrast is uitgeschakeld."} '
                   'Schakel deze optie in voor betere zichtbaarheid van tekst en elementen.';
          break;
        default:
          content = 'Thema instellingen beschikbaar.';
      }
      
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak(content);
    } catch (e) {
      debugPrint('Error reading theme settings: $e');
    }
  }

  // Public static methods for content extraction (used by UniversalTTSService)
  
  /// Extract forum posts content for TTS
  static String extractForumPostsContent(BuildContext context) {
    return _extractForumPostsContent(context);
  }

  /// Extract forum post detail content for TTS
  static String extractForumPostDetailContent(BuildContext context) {
    return _extractForumPostDetailContent(context);
  }

  /// Extract form content for TTS
  static String extractFormContent(BuildContext context) {
    return _extractFormContent(context);
  }
}

/// Provider for the context-aware page TTS service
final contextAwarePageTTSServiceProvider = Provider<ContextAwarePageTTSService>((ref) {
  return ContextAwarePageTTSService();
});
