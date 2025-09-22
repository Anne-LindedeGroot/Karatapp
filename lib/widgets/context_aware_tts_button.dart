import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../services/context_aware_tts_service.dart';

/// Context-aware TTS button that reads content specific to the current section
class ContextAwareTTSButton extends ConsumerWidget {
  final TTSPageType pageType;
  final String? customContent;
  final String? pageTitle;
  final IconData? icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? size;
  final bool isFloating;

  const ContextAwareTTSButton({
    super.key,
    required this.pageType,
    this.customContent,
    this.pageTitle,
    this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.size,
    this.isFloating = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final isReading = ContextAwareTTSService.isReading;
    final currentPageType = ContextAwareTTSService.currentPageType;
    
    // Check if currently reading this specific page type
    final isReadingThisContext = isReading && currentPageType == pageType;

    final effectiveIcon = icon ?? 
        (isReadingThisContext ? Icons.stop : Icons.volume_up);
    
    final effectiveTooltip = tooltip ?? 
        (isReadingThisContext ? 'Stop voorlezen' : _getContextTooltip());

    final effectiveBackgroundColor = backgroundColor ?? 
        (accessibilityState.isTextToSpeechEnabled
            ? (isReadingThisContext ? Colors.red : Theme.of(context).colorScheme.primary)
            : Theme.of(context).colorScheme.secondary);

    final effectiveForegroundColor = foregroundColor ?? 
        (accessibilityState.isTextToSpeechEnabled
            ? (isReadingThisContext ? Colors.white : Theme.of(context).colorScheme.onPrimary)
            : Theme.of(context).colorScheme.onSecondary);

    if (isFloating) {
      return FloatingActionButton(
        onPressed: () => _handleTap(context, ref),
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: effectiveForegroundColor,
        tooltip: effectiveTooltip,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            effectiveIcon,
            key: ValueKey(effectiveIcon),
            size: size ?? 28,
          ),
        ),
      );
    }

    return IconButton(
      onPressed: () => _handleTap(context, ref),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          effectiveIcon,
          key: ValueKey(effectiveIcon),
          size: size ?? 24,
          color: effectiveForegroundColor,
        ),
      ),
      tooltip: effectiveTooltip,
      style: IconButton.styleFrom(
        backgroundColor: effectiveBackgroundColor,
        foregroundColor: effectiveForegroundColor,
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref) {
    ContextAwareTTSService.readPageContent(
      context, 
      ref, 
      pageType,
      customContent: customContent,
      pageTitle: pageTitle,
    );
  }

  String _getContextTooltip() {
    switch (pageType) {
      case TTSPageType.home:
        return 'Hoofdpagina voorlezen';
      case TTSPageType.forum:
        return 'Forum voorlezen';
      case TTSPageType.forumPostDetail:
        return 'Bericht voorlezen';
      case TTSPageType.custom:
        return 'Inhoud voorlezen';
    }
  }
}

/// Specialized TTS button for home/kata list sections
class HomeTTSButton extends StatelessWidget {
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const HomeTTSButton({
    super.key,
    this.size,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ContextAwareTTSButton(
      pageType: TTSPageType.home,
      icon: Icons.home,
      size: size,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}

/// Specialized TTS button for forum sections
class ForumTTSButton extends StatelessWidget {
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ForumTTSButton({
    super.key,
    this.size,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ContextAwareTTSButton(
      pageType: TTSPageType.forum,
      icon: Icons.forum,
      size: size,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}

/// Specialized TTS button for forum post details
class ForumPostTTSButton extends StatelessWidget {
  final String postTitle;
  final String postContent;
  final List<String> comments;
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ForumPostTTSButton({
    super.key,
    required this.postTitle,
    required this.postContent,
    this.comments = const [],
    this.size,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ContextAwareTTSButton(
      pageType: TTSPageType.forumPostDetail,
      pageTitle: postTitle,
      customContent: postContent,
      icon: Icons.article,
      size: size,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}

/// Specialized TTS button for custom content
class CustomTTSButton extends StatelessWidget {
  final String content;
  final String? title;
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const CustomTTSButton({
    super.key,
    required this.content,
    this.title,
    this.size,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return ContextAwareTTSButton(
      pageType: TTSPageType.custom,
      customContent: content,
      pageTitle: title,
      icon: Icons.record_voice_over,
      size: size,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
    );
  }
}

/// Floating context-aware TTS button that adapts to the current screen
class ContextAwareFloatingTTSButton extends ConsumerWidget {
  final String currentRoute;

  const ContextAwareFloatingTTSButton({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageType = _getPageTypeFromRoute(currentRoute);
    
    return ContextAwareTTSButton(
      pageType: pageType,
      isFloating: true,
    );
  }

  TTSPageType _getPageTypeFromRoute(String route) {
    switch (route) {
      case '/':
      case '/home':
        return TTSPageType.home;
      case '/forum':
        return TTSPageType.forum;
      default:
        // Default to home for unknown routes
        return TTSPageType.home;
    }
  }
}
