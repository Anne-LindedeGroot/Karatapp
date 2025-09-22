import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../services/universal_tts_service.dart';

/// A global TTS overlay that can be positioned anywhere on the screen
/// and provides TTS functionality for the entire app
class GlobalTTSOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final bool showOverlay;
  final Alignment alignment;
  final EdgeInsets margin;

  const GlobalTTSOverlay({
    super.key,
    required this.child,
    this.showOverlay = true,
    this.alignment = Alignment.bottomRight,
    this.margin = const EdgeInsets.all(16),
  });

  @override
  ConsumerState<GlobalTTSOverlay> createState() => _GlobalTTSOverlayState();
}

class _GlobalTTSOverlayState extends ConsumerState<GlobalTTSOverlay>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.125, // 45 degrees (1/8 turn)
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showOverlay) {
      return widget.child;
    }

    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomRight, // Use non-directional alignment
            child: Container(
              margin: widget.margin,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Quick action buttons (when expanded)
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: _isExpanded
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Text-to-speech toggle
                                  _GlobalTTSActionButton(
                                    icon: accessibilityState.isTextToSpeechEnabled
                                        ? Icons.headphones
                                        : Icons.headphones_outlined,
                                    label: accessibilityState.isTextToSpeechEnabled
                                        ? 'Spraak uit'
                                        : 'Spraak aan',
                                    isActive: accessibilityState.isTextToSpeechEnabled,
                                    onPressed: () async {
                                      await accessibilityNotifier.toggleTextToSpeech();
                                      
                                      // Wait for state to update and then provide feedback
                                      await Future.delayed(const Duration(milliseconds: 200));
                                      final newState = ref.read(accessibilityNotifierProvider);
                                      if (newState.isTextToSpeechEnabled) {
                                        await accessibilityNotifier.speak('Spraak is nu ingeschakeld voor de hele app');
                                      } else {
                                        // Don't speak when disabling TTS
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 8),

                                  // Font size toggle
                                  _GlobalTTSActionButton(
                                    icon: _getFontSizeIcon(accessibilityState.fontSize),
                                    label: 'Lettergrootte: ${accessibilityState.fontSizeDescription}',
                                    isActive: accessibilityState.fontSize != AccessibilityFontSize.normal,
                                    onPressed: () async {
                                      await accessibilityNotifier.toggleFontSize();
                                      if (accessibilityState.isTextToSpeechEnabled) {
                                        await accessibilityNotifier.speak('Lettergrootte gewijzigd naar ${accessibilityState.fontSizeDescription}');
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 8),

                                  // Dyslexia toggle
                                  _GlobalTTSActionButton(
                                    icon: accessibilityState.isDyslexiaFriendly
                                        ? Icons.text_format
                                        : Icons.font_download,
                                    label: accessibilityState.isDyslexiaFriendly
                                        ? 'Dyslexie uit'
                                        : 'Dyslexie aan',
                                    isActive: accessibilityState.isDyslexiaFriendly,
                                    onPressed: () async {
                                      await accessibilityNotifier.toggleDyslexiaFriendly();
                                      if (accessibilityState.isTextToSpeechEnabled) {
                                        final status = accessibilityState.isDyslexiaFriendly ? 'uitgeschakeld' : 'ingeschakeld';
                                        await accessibilityNotifier.speak('Dyslexie vriendelijke modus $status');
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 8),

                                  // Page reader button
                                  _GlobalTTSActionButton(
                                    icon: Icons.record_voice_over,
                                    label: 'Pagina voorlezen',
                                    isActive: false,
                                    onPressed: () async {
                                      if (accessibilityState.isTextToSpeechEnabled) {
                                        await _readCurrentPage();
                                      } else {
                                        // Enable TTS first, then read
                                        await accessibilityNotifier.toggleTextToSpeech();
                                        await Future.delayed(const Duration(milliseconds: 500));
                                        await _readCurrentPage();
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 8),

                                  // Stop speaking button
                                  if (accessibilityState.isTextToSpeechEnabled)
                                    _GlobalTTSActionButton(
                                      icon: Icons.stop,
                                      label: 'Stop spraak',
                                      isActive: false,
                                      backgroundColor: Colors.red,
                                      onPressed: () async {
                                        await accessibilityNotifier.stopSpeaking();
                                      },
                                    ),
                                  const SizedBox(height: 16),
                                ],
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                  ),

                  // Main TTS button
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 2 * 3.14159,
                        child: FloatingActionButton(
                          onPressed: _toggleExpanded,
                          backgroundColor: accessibilityState.isTextToSpeechEnabled
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                          foregroundColor: accessibilityState.isTextToSpeechEnabled
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSecondary,
                          child: Icon(
                            _isExpanded ? Icons.close : Icons.accessibility,
                            size: 28,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Get appropriate icon for font size
  IconData _getFontSizeIcon(AccessibilityFontSize fontSize) {
    switch (fontSize) {
      case AccessibilityFontSize.small:
        return Icons.text_decrease;
      case AccessibilityFontSize.normal:
        return Icons.text_fields;
      case AccessibilityFontSize.large:
        return Icons.text_increase;
      case AccessibilityFontSize.extraLarge:
        return Icons.format_size;
    }
  }

  /// Read the current page content
  Future<void> _readCurrentPage() async {
    // Use the new comprehensive page reading from UniversalTTSService
    await UniversalTTSService.readEntirePage(context, ref);
  }


}

/// Individual action button for the global TTS overlay
class _GlobalTTSActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const _GlobalTTSActionButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: onPressed,
      backgroundColor: backgroundColor ?? (isActive 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.secondary),
      foregroundColor: isActive 
        ? Theme.of(context).colorScheme.onPrimary 
        : Theme.of(context).colorScheme.onSecondary,
      heroTag: label, // Unique hero tag to avoid conflicts
      child: Icon(icon, size: 20),
    );
  }
}

/// A compact global TTS button that can be placed in app bars
class GlobalTTSAppBarButton extends ConsumerWidget {
  final String? customPageDescription;

  const GlobalTTSAppBarButton({
    super.key,
    this.customPageDescription,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    return PopupMenuButton<String>(
      icon: Icon(
        accessibilityState.isTextToSpeechEnabled 
          ? Icons.accessibility 
          : Icons.accessibility_outlined,
        color: accessibilityState.isTextToSpeechEnabled 
          ? Theme.of(context).colorScheme.primary 
          : null,
      ),
      tooltip: 'Toegankelijkheid',
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'toggle_tts',
          child: Row(
            children: [
              Icon(
                accessibilityState.isTextToSpeechEnabled 
                  ? Icons.headphones 
                  : Icons.headphones_outlined,
                size: 20,
                color: accessibilityState.isTextToSpeechEnabled 
                  ? Theme.of(context).colorScheme.primary 
                  : null,
              ),
              const SizedBox(width: 12),
              Text(accessibilityState.isTextToSpeechEnabled 
                ? 'Spraak uitschakelen' 
                : 'Spraak inschakelen'),
            ],
          ),
        ),
        if (accessibilityState.isTextToSpeechEnabled) ...[
          PopupMenuItem<String>(
            value: 'read_page',
            child: const Row(
              children: [
                Icon(Icons.record_voice_over, size: 20),
                SizedBox(width: 12),
                Text('Pagina voorlezen'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'stop_speaking',
            child: const Row(
              children: [
                Icon(Icons.stop, size: 20, color: Colors.red),
                SizedBox(width: 12),
                Text('Stop spraak', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'font_size',
          child: Row(
            children: [
              const Icon(Icons.text_fields, size: 20),
              const SizedBox(width: 12),
              Text('Lettergrootte: ${accessibilityState.fontSizeDescription}'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'dyslexia',
          child: Row(
            children: [
              Icon(
                accessibilityState.isDyslexiaFriendly 
                  ? Icons.text_format 
                  : Icons.font_download,
                size: 20,
                color: accessibilityState.isDyslexiaFriendly 
                  ? Theme.of(context).colorScheme.primary 
                  : null,
              ),
              const SizedBox(width: 12),
              const Text('Dyslexie vriendelijk'),
              const Spacer(),
              Switch(
                value: accessibilityState.isDyslexiaFriendly,
                onChanged: (value) {
                  accessibilityNotifier.toggleDyslexiaFriendly();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ],
      onSelected: (String value) async {
        switch (value) {
          case 'toggle_tts':
            await accessibilityNotifier.toggleTextToSpeech();
            if (!accessibilityState.isTextToSpeechEnabled) {
              await Future.delayed(const Duration(milliseconds: 100));
              await accessibilityNotifier.speak('Spraak is nu ingeschakeld');
            }
            break;
          case 'read_page':
            final pageDescription = customPageDescription ?? 
              'Deze pagina bevat verschillende elementen die je kunt gebruiken.';
            await accessibilityNotifier.speak(pageDescription);
            break;
          case 'stop_speaking':
            await accessibilityNotifier.stopSpeaking();
            break;
          case 'font_size':
            await accessibilityNotifier.toggleFontSize();
            if (accessibilityState.isTextToSpeechEnabled) {
              await accessibilityNotifier.speak('Lettergrootte gewijzigd');
            }
            break;
          case 'dyslexia':
            await accessibilityNotifier.toggleDyslexiaFriendly();
            if (accessibilityState.isTextToSpeechEnabled) {
              final status = accessibilityState.isDyslexiaFriendly ? 'uitgeschakeld' : 'ingeschakeld';
              await accessibilityNotifier.speak('Dyslexie vriendelijke modus $status');
            }
            break;
        }
      },
    );
  }
}

/// A widget that automatically speaks its content when TTS is enabled
class AutoSpeakWidget extends ConsumerStatefulWidget {
  final String text;
  final Widget child;
  final bool speakOnBuild;
  final Duration delay;

  const AutoSpeakWidget({
    super.key,
    required this.text,
    required this.child,
    this.speakOnBuild = false,
    this.delay = const Duration(milliseconds: 500),
  });

  @override
  ConsumerState<AutoSpeakWidget> createState() => _AutoSpeakWidgetState();
}

class _AutoSpeakWidgetState extends ConsumerState<AutoSpeakWidget> {
  @override
  void initState() {
    super.initState();
    if (widget.speakOnBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _speakText();
      });
    }
  }

  void _speakText() async {
    final isTextToSpeechEnabled = ref.read(isTextToSpeechEnabledProvider);
    if (isTextToSpeechEnabled) {
      await Future.delayed(widget.delay);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak(widget.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _speakText,
      child: widget.child,
    );
  }
}
