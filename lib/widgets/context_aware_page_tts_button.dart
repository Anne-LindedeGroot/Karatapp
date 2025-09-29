import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../services/context_aware_page_tts_service.dart';

/// Context-aware TTS button that reads specific content based on the screen/component context
class ContextAwarePageTTSButton extends ConsumerWidget {
  final PageTTSContext context;
  final String? customTab; // For favorites screen
  final bool isEdit; // For kata forms
  final EdgeInsets? margin;
  final double? iconSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final String? tooltip;
  final bool showLabel;

  const ContextAwarePageTTSButton({
    super.key,
    required this.context,
    this.customTab,
    this.isEdit = false,
    this.margin,
    this.iconSize = 24.0,
    this.activeColor,
    this.inactiveColor,
    this.tooltip,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;
    final isSpeaking = accessibilityState.isSpeaking;
    final effectiveActiveColor = activeColor ?? Theme.of(context).colorScheme.primary;
    final effectiveInactiveColor = inactiveColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final speakingColor = Colors.green;

    return Container(
      margin: margin,
      child: showLabel 
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconButton(context, isEnabled, isSpeaking, effectiveActiveColor, effectiveInactiveColor, speakingColor, accessibilityNotifier, ref),
              const SizedBox(height: 4),
              Text(
                isSpeaking ? 'Aan het spreken' : (isEnabled ? 'Spraak aan' : 'Spraak uit'),
                style: TextStyle(
                  fontSize: 10,
                  color: isSpeaking ? speakingColor : (isEnabled ? effectiveActiveColor : effectiveInactiveColor),
                  fontWeight: (isEnabled || isSpeaking) ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          )
        : _buildIconButton(context, isEnabled, isSpeaking, effectiveActiveColor, effectiveInactiveColor, speakingColor, accessibilityNotifier, ref),
    );
  }

  Widget _buildIconButton(
    BuildContext context, 
    bool isEnabled, 
    bool isSpeaking,
    Color activeColor, 
    Color inactiveColor, 
    Color speakingColor,
    AccessibilityNotifier accessibilityNotifier,
    WidgetRef ref
  ) {
    return IconButton(
      icon: Icon(
        isSpeaking 
          ? Icons.volume_up 
          : (isEnabled ? Icons.headphones : Icons.headphones_outlined),
        size: iconSize,
        color: isSpeaking 
          ? speakingColor 
          : (isEnabled ? activeColor : inactiveColor),
      ),
      tooltip: tooltip ?? _getContextTooltip(isSpeaking, isEnabled),
      onPressed: () async {
        if (isSpeaking) {
          // Stop speaking if currently speaking
          await accessibilityNotifier.stopSpeaking();
        } else if (isEnabled) {
          // Read the specific context content
          await _readContextContent(context, ref);
        } else {
          // Enable TTS first, then read content
          await accessibilityNotifier.toggleTextToSpeech();
          await Future.delayed(const Duration(milliseconds: 300));
          await _readContextContent(context, ref);
        }
      },
    );
  }

  String _getContextTooltip(bool isSpeaking, bool isEnabled) {
    if (isSpeaking) {
      return 'Stop spraak';
    } else if (isEnabled) {
      return _getReadActionText();
    } else {
      return 'Spraak inschakelen en ${_getReadActionText().toLowerCase()}';
    }
  }

  String _getReadActionText() {
    switch (context) {
      case PageTTSContext.profile:
        return 'Profiel voorlezen';
      case PageTTSContext.kataForm:
        return isEdit ? 'Kata bewerken formulier voorlezen' : 'Kata aanmaken formulier voorlezen';
      case PageTTSContext.kataComments:
        return 'Kata reacties voorlezen';
      case PageTTSContext.favorites:
        return 'Favorieten voorlezen';
      case PageTTSContext.forumHome:
        return 'Forum berichten voorlezen';
      case PageTTSContext.forumPostForm:
        return 'Forum bericht formulier voorlezen';
      case PageTTSContext.forumPostDetail:
        return 'Forum bericht en reacties voorlezen';
      case PageTTSContext.userManagement:
        return 'Gebruikersbeheer voorlezen';
      case PageTTSContext.deletePopup:
        return 'Verwijder popup voorlezen';
      case PageTTSContext.cleanImagesPopup:
        return 'Afbeeldingen opruimen popup voorlezen';
      case PageTTSContext.logoutPopup:
        return 'Uitloggen popup voorlezen';
      case PageTTSContext.appBarAndHome:
        return 'App balk en hoofdpagina voorlezen';
      case PageTTSContext.menu:
        return 'Menu voorlezen';
    }
  }

  Future<void> _readContextContent(BuildContext context, WidgetRef ref) async {
    try {
      switch (this.context) {
        case PageTTSContext.profile:
          await ContextAwarePageTTSService.readProfileScreen(context, ref);
          break;
        case PageTTSContext.kataForm:
          await ContextAwarePageTTSService.readKataForm(context, ref, isEdit: isEdit);
          break;
        case PageTTSContext.kataComments:
          await ContextAwarePageTTSService.readKataComments(context, ref);
          break;
        case PageTTSContext.favorites:
          await ContextAwarePageTTSService.readFavoritesScreen(context, ref, customTab ?? 'katas');
          break;
        case PageTTSContext.forumHome:
          await ContextAwarePageTTSService.readForumHomePage(context, ref);
          break;
        case PageTTSContext.forumPostForm:
          await ContextAwarePageTTSService.readForumPostForm(context, ref);
          break;
        case PageTTSContext.forumPostDetail:
          await ContextAwarePageTTSService.readForumPostDetail(context, ref);
          break;
        case PageTTSContext.userManagement:
          await ContextAwarePageTTSService.readUserManagementScreen(context, ref);
          break;
        case PageTTSContext.deletePopup:
          await ContextAwarePageTTSService.readDeletePopup(context, ref);
          break;
        case PageTTSContext.cleanImagesPopup:
          await ContextAwarePageTTSService.readCleanImagesPopup(context, ref);
          break;
        case PageTTSContext.logoutPopup:
          await ContextAwarePageTTSService.readLogoutPopup(context, ref);
          break;
        case PageTTSContext.appBarAndHome:
          await ContextAwarePageTTSService.readAppBarAndHomePage(context, ref);
          break;
        case PageTTSContext.menu:
          await ContextAwarePageTTSService.readMenuContent(context, ref);
          break;
      }
    } catch (e) {
      debugPrint('Error reading context content: $e');
      // Fallback to generic message
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Er was een probleem bij het voorlezen van de inhoud.');
    }
  }
}

/// Compact version for smaller spaces
class CompactContextAwarePageTTSButton extends ConsumerWidget {
  final PageTTSContext context;
  final String? customTab;
  final bool isEdit;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CompactContextAwarePageTTSButton({
    super.key,
    required this.context,
    this.customTab,
    this.isEdit = false,
    this.margin,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;
    final isSpeaking = accessibilityState.isSpeaking;

    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      child: FloatingActionButton.small(
        onPressed: () async {
          if (isSpeaking) {
            await accessibilityNotifier.stopSpeaking();
          } else if (isEnabled) {
            await _readContextContent(context, ref);
          } else {
            await accessibilityNotifier.toggleTextToSpeech();
            await Future.delayed(const Duration(milliseconds: 300));
            await _readContextContent(context, ref);
          }
        },
        backgroundColor: backgroundColor ?? (isSpeaking 
          ? Colors.green 
          : (isEnabled 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.secondary)),
        foregroundColor: foregroundColor ?? (isSpeaking || isEnabled 
          ? Theme.of(context).colorScheme.onPrimary 
          : Theme.of(context).colorScheme.onSecondary),
        tooltip: _getContextTooltip(isSpeaking, isEnabled),
        child: Icon(
          isSpeaking 
            ? Icons.volume_up 
            : (isEnabled ? Icons.headphones : Icons.headphones_outlined),
          size: 20,
        ),
      ),
    );
  }

  String _getContextTooltip(bool isSpeaking, bool isEnabled) {
    if (isSpeaking) {
      return 'Stop spraak';
    } else if (isEnabled) {
      return _getReadActionText();
    } else {
      return 'Spraak inschakelen';
    }
  }

  String _getReadActionText() {
    switch (context) {
      case PageTTSContext.profile:
        return 'Profiel voorlezen';
      case PageTTSContext.kataForm:
        return isEdit ? 'Kata bewerken formulier voorlezen' : 'Kata aanmaken formulier voorlezen';
      case PageTTSContext.kataComments:
        return 'Kata reacties voorlezen';
      case PageTTSContext.favorites:
        return 'Favorieten voorlezen';
      case PageTTSContext.forumHome:
        return 'Forum berichten voorlezen';
      case PageTTSContext.forumPostForm:
        return 'Forum bericht formulier voorlezen';
      case PageTTSContext.forumPostDetail:
        return 'Forum bericht en reacties voorlezen';
      case PageTTSContext.userManagement:
        return 'Gebruikersbeheer voorlezen';
      case PageTTSContext.deletePopup:
        return 'Verwijder popup voorlezen';
      case PageTTSContext.cleanImagesPopup:
        return 'Afbeeldingen opruimen popup voorlezen';
      case PageTTSContext.logoutPopup:
        return 'Uitloggen popup voorlezen';
      case PageTTSContext.appBarAndHome:
        return 'App balk en hoofdpagina voorlezen';
      case PageTTSContext.menu:
        return 'Menu voorlezen';
    }
  }

  Future<void> _readContextContent(BuildContext context, WidgetRef ref) async {
    try {
      switch (this.context) {
        case PageTTSContext.profile:
          await ContextAwarePageTTSService.readProfileScreen(context, ref);
          break;
        case PageTTSContext.kataForm:
          await ContextAwarePageTTSService.readKataForm(context, ref, isEdit: isEdit);
          break;
        case PageTTSContext.kataComments:
          await ContextAwarePageTTSService.readKataComments(context, ref);
          break;
        case PageTTSContext.favorites:
          await ContextAwarePageTTSService.readFavoritesScreen(context, ref, customTab ?? 'katas');
          break;
        case PageTTSContext.forumHome:
          await ContextAwarePageTTSService.readForumHomePage(context, ref);
          break;
        case PageTTSContext.forumPostForm:
          await ContextAwarePageTTSService.readForumPostForm(context, ref);
          break;
        case PageTTSContext.forumPostDetail:
          await ContextAwarePageTTSService.readForumPostDetail(context, ref);
          break;
        case PageTTSContext.userManagement:
          await ContextAwarePageTTSService.readUserManagementScreen(context, ref);
          break;
        case PageTTSContext.deletePopup:
          await ContextAwarePageTTSService.readDeletePopup(context, ref);
          break;
        case PageTTSContext.cleanImagesPopup:
          await ContextAwarePageTTSService.readCleanImagesPopup(context, ref);
          break;
        case PageTTSContext.logoutPopup:
          await ContextAwarePageTTSService.readLogoutPopup(context, ref);
          break;
        case PageTTSContext.appBarAndHome:
          await ContextAwarePageTTSService.readAppBarAndHomePage(context, ref);
          break;
        case PageTTSContext.menu:
          await ContextAwarePageTTSService.readMenuContent(context, ref);
          break;
      }
    } catch (e) {
      debugPrint('Error reading context content: $e');
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Er was een probleem bij het voorlezen van de inhoud.');
    }
  }
}

/// Dialog version for popups
class DialogContextAwarePageTTSButton extends ConsumerWidget {
  final PageTTSContext context;
  final bool showBackground;
  final EdgeInsets? padding;

  const DialogContextAwarePageTTSButton({
    super.key,
    required this.context,
    this.showBackground = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;
    final isSpeaking = accessibilityState.isSpeaking;

    Widget button = IconButton(
      icon: Icon(
        isSpeaking 
          ? Icons.volume_up 
          : (isEnabled ? Icons.headphones : Icons.headphones_outlined),
        color: isSpeaking 
          ? Colors.green 
          : (isEnabled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      tooltip: _getContextTooltip(isSpeaking, isEnabled),
      onPressed: () async {
        if (isSpeaking) {
          await accessibilityNotifier.stopSpeaking();
        } else if (isEnabled) {
          await _readContextContent(context, ref);
        } else {
          await accessibilityNotifier.toggleTextToSpeech();
          await Future.delayed(const Duration(milliseconds: 300));
          await _readContextContent(context, ref);
        }
      },
    );

    if (showBackground) {
      button = Container(
        padding: padding ?? const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSpeaking 
            ? Colors.green.withValues(alpha: 0.1)
            : (isEnabled 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
          border: (isEnabled || isSpeaking)
            ? Border.all(color: (isSpeaking ? Colors.green : Theme.of(context).colorScheme.primary).withValues(alpha: 0.3))
            : null,
        ),
        child: button,
      );
    }

    return button;
  }

  String _getContextTooltip(bool isSpeaking, bool isEnabled) {
    if (isSpeaking) {
      return 'Stop spraak';
    } else if (isEnabled) {
      return _getReadActionText();
    } else {
      return 'Spraak inschakelen';
    }
  }

  String _getReadActionText() {
    switch (context) {
      case PageTTSContext.deletePopup:
        return 'Verwijder popup voorlezen';
      case PageTTSContext.cleanImagesPopup:
        return 'Afbeeldingen opruimen popup voorlezen';
      case PageTTSContext.logoutPopup:
        return 'Uitloggen popup voorlezen';
      default:
        return 'Popup voorlezen';
    }
  }

  Future<void> _readContextContent(BuildContext context, WidgetRef ref) async {
    try {
      switch (this.context) {
        case PageTTSContext.deletePopup:
          await ContextAwarePageTTSService.readDeletePopup(context, ref);
          break;
        case PageTTSContext.cleanImagesPopup:
          await ContextAwarePageTTSService.readCleanImagesPopup(context, ref);
          break;
        case PageTTSContext.logoutPopup:
          await ContextAwarePageTTSService.readLogoutPopup(context, ref);
          break;
        default:
          // Fallback for other contexts
          final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
          await accessibilityNotifier.speak('Popup inhoud beschikbaar.');
          break;
      }
    } catch (e) {
      debugPrint('Error reading context content: $e');
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Er was een probleem bij het voorlezen van de popup inhoud.');
    }
  }
}

/// Enum defining different page/component contexts for TTS
enum PageTTSContext {
  profile,
  kataForm,
  kataComments,
  favorites,
  forumHome,
  forumPostForm,
  forumPostDetail,
  userManagement,
  deletePopup,
  cleanImagesPopup,
  logoutPopup,
  appBarAndHome,
  menu,
}
