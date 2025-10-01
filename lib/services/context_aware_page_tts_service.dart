import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';
import '../services/universal_tts_service.dart';
import '../services/role_service.dart';

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
      await accessibilityNotifier.speak('Profiel pagina. $content');
    } catch (e) {
      debugPrint('Error reading profile screen: $e');
    }
  }

  /// Read kata form content (add/edit)
  static Future<void> readKataForm(BuildContext context, WidgetRef ref, {bool isEdit = false}) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    try {
      final content = _extractFormContent(context);
      final formType = isEdit ? 'Kata bewerken' : 'Nieuwe kata aanmaken';
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('$formType formulier. $content');
    } catch (e) {
      debugPrint('Error reading kata form: $e');
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
      
      content.write('Gebruikersprofiel. ');
      
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
    
    // Look for post-like content
    final lines = bodyText.split('\n').where((line) => line.trim().isNotEmpty).toList();
    int postCount = 0;
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.length > 15 && !trimmedLine.contains('knop') && !trimmedLine.contains('invoerveld')) {
        postCount++;
        if (postCount <= 3) { // Limit to first 3 posts
          content.write('Bericht $postCount: $trimmedLine. ');
        }
      }
    }
    
    if (postCount > 3) {
      content.write('En ${postCount - 3} meer berichten. ');
    }
    
    if (postCount == 0) {
      content.write('Nog geen berichten geplaatst. ');
    }
    
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
      content.write('Bericht inhoud: ${lines.first}. ');
      
      // Look for comments
      int commentCount = 0;
      for (int i = 1; i < lines.length; i++) {
        final trimmedLine = lines[i].trim();
        if (trimmedLine.length > 15 && !trimmedLine.contains('knop')) {
          commentCount++;
          if (commentCount <= 3) {
            content.write('Reactie $commentCount: $trimmedLine. ');
          }
        }
      }
      
      if (commentCount > 3) {
        content.write('En ${commentCount - 3} meer reacties. ');
      }
    }
    
    return content.toString().isNotEmpty ? content.toString() : 'Bericht details geladen.';
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
          if (kataCount <= 3) { // Limit to first 3 katas
            content.write('Kata $kataCount: $trimmedLine. ');
          }
        }
      }
      
      if (kataCount > 3) {
        content.write('En ${kataCount - 3} meer kata\'s beschikbaar. ');
      }
      
      if (kataCount == 0) {
        content.write('Kata overzicht geladen. ');
      }
    }
    
    return content.toString().isNotEmpty ? content.toString() : 'Hoofdpagina met app balk geladen.';
  }

  static String _extractMenuContent(BuildContext context) {
    final StringBuffer content = StringBuffer();
    
    // Since this is a popup menu, we'll provide a comprehensive description
    content.write('Gebruikersmenu geopend. ');
    content.write('Beschikbare opties: ');
    content.write('Profiel - ga naar je profiel pagina. ');
    content.write('Mijn Favorieten - bekijk je opgeslagen favoriete kata\'s en forum berichten. ');
    content.write('Gebruikersbeheer - beheer gebruikers en rollen, alleen voor beheerders. ');
    content.write('Afbeeldingen opruimen - verwijder verweesde afbeeldingen uit de opslag. ');
    content.write('Thema instellingen - kies tussen licht, donker of systeem thema. ');
    content.write('Hoog contrast - schakel hoog contrast modus in of uit voor betere zichtbaarheid. ');
    content.write('Uitloggen - log uit van de applicatie. ');
    
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
}

/// Provider for the context-aware page TTS service
final contextAwarePageTTSServiceProvider = Provider<ContextAwarePageTTSService>((ref) {
  return ContextAwarePageTTSService();
});
