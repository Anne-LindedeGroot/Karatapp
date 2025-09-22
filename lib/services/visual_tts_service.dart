import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../providers/kata_provider.dart';

/// Visual TTS Service with highlighting like ReadSpeaker
class VisualTTSService {
  static final VisualTTSService _instance = VisualTTSService._internal();
  factory VisualTTSService() => _instance;
  VisualTTSService._internal();

  /// Read entire page with visual highlighting
  static Future<void> readPageWithHighlighting(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) {
      // Enable TTS first
      await ref.read(accessibilityNotifierProvider.notifier).setTextToSpeechEnabled(true);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      
      // Check if context is still mounted before using it
      if (!context.mounted) return;
      
      // Find the Scaffold and read content sequentially
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      
      // Start with page introduction
      await _speakWithHighlight(
        context, 
        'Je bent op de hoofdpagina waar je alle kata\'s kunt bekijken en zoeken',
        accessibilityNotifier,
        highlightType: HighlightType.page
      );
      
      if (scaffold != null && context.mounted) {
        
        // 1. Read AppBar with highlighting
        if (scaffold.appBar != null && context.mounted) {
          await _speakWithHighlight(
            context,
            'Karatapp',
            accessibilityNotifier,
            highlightType: HighlightType.appBar
          );
        }
        
        // 2. Read search bar
        if (context.mounted) {
          await _speakWithHighlight(
            context,
            'Zoek kata\'s invoerveld',
            accessibilityNotifier,
            highlightType: HighlightType.searchBar
          );
        }
        
        // 3. Read kata cards sequentially
        if (context.mounted) {
          await _readKataCardsSequentially(context, ref, accessibilityNotifier);
        }
      }
      
    } catch (e) {
      debugPrint('Error reading page with highlighting: $e');
    }
  }

  /// Read kata cards one by one with highlighting
  static Future<void> _readKataCardsSequentially(
    BuildContext context, 
    WidgetRef ref, 
    AccessibilityNotifier accessibilityNotifier
  ) async {
    // Get kata data from provider
    final kataState = ref.read(kataNotifierProvider);
    final katas = kataState.filteredKatas;
    
    for (int i = 0; i < katas.length; i++) {
      final kata = katas[i];
      
      // Check if context is still mounted before each operation
      if (!context.mounted) return;
      
      // Highlight and read each kata
      await _speakWithHighlight(
        context,
        'Kata ${i + 1}: ${kata.name}',
        accessibilityNotifier,
        highlightType: HighlightType.kataTitle,
        kataIndex: i
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!context.mounted) return;
      
      await _speakWithHighlight(
        context,
        'Stijl: ${kata.style}',
        accessibilityNotifier,
        highlightType: HighlightType.kataStyle,
        kataIndex: i
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!context.mounted) return;
      
      if (kata.description.isNotEmpty) {
        await _speakWithHighlight(
          context,
          'Beschrijving: ${kata.description}',
          accessibilityNotifier,
          highlightType: HighlightType.kataDescription,
          kataIndex: i
        );
      }
      
      // Small pause between katas
      await Future.delayed(const Duration(milliseconds: 800));
    }
  }

  /// Speak text with visual highlighting
  static Future<void> _speakWithHighlight(
    BuildContext context,
    String text,
    AccessibilityNotifier accessibilityNotifier,
    {required HighlightType highlightType, int? kataIndex}
  ) async {
    
    // Show visual highlight
    _showHighlight(context, highlightType, kataIndex);
    
    // Speak the text
    await accessibilityNotifier.speak(text);
    
    // Check if context is still mounted before removing highlight
    if (context.mounted) {
      // Remove highlight after speaking
      _removeHighlight(context);
    }
  }

  /// Show visual highlight on the element being read
  static void _showHighlight(BuildContext context, HighlightType type, int? kataIndex) {
    // Create overlay with highlight
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => VisualHighlightWidget(
        highlightType: type,
        kataIndex: kataIndex,
      ),
    );
    
    overlay.insert(overlayEntry);
    
    // Store overlay entry for removal
    _currentHighlightOverlay = overlayEntry;
  }

  /// Remove visual highlight
  static void _removeHighlight(BuildContext context) {
    _currentHighlightOverlay?.remove();
    _currentHighlightOverlay = null;
  }

  static OverlayEntry? _currentHighlightOverlay;
}

/// Types of elements that can be highlighted
enum HighlightType {
  page,
  appBar,
  searchBar,
  kataTitle,
  kataStyle,
  kataDescription,
  kataComments
}

/// Widget that shows visual highlighting
class VisualHighlightWidget extends StatefulWidget {
  final HighlightType highlightType;
  final int? kataIndex;

  const VisualHighlightWidget({
    super.key,
    required this.highlightType,
    this.kataIndex,
  });

  @override
  State<VisualHighlightWidget> createState() => _VisualHighlightWidgetState();
}

class _VisualHighlightWidgetState extends State<VisualHighlightWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: HighlightPainter(
              highlightType: widget.highlightType,
              kataIndex: widget.kataIndex,
              animationValue: _pulseAnimation.value,
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for drawing highlights
class HighlightPainter extends CustomPainter {
  final HighlightType highlightType;
  final int? kataIndex;
  final double animationValue;

  HighlightPainter({
    required this.highlightType,
    this.kataIndex,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.3 * animationValue)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.8 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    Rect highlightRect;

    switch (highlightType) {
      case HighlightType.page:
        // Highlight entire screen briefly
        highlightRect = Rect.fromLTWH(0, 0, size.width, size.height);
        break;
        
      case HighlightType.appBar:
        // Highlight app bar area
        highlightRect = Rect.fromLTWH(0, 0, size.width, 80);
        break;
        
      case HighlightType.searchBar:
        // Highlight search bar area
        highlightRect = Rect.fromLTWH(16, 90, size.width - 32, 60);
        break;
        
      case HighlightType.kataTitle:
      case HighlightType.kataStyle:
      case HighlightType.kataDescription:
        // Highlight specific kata card
        final cardTop = 170 + (kataIndex ?? 0) * 200.0;
        highlightRect = Rect.fromLTWH(16, cardTop, size.width - 32, 180);
        break;
        
      case HighlightType.kataComments:
        // Highlight comments section of specific kata
        final cardTop = 170 + (kataIndex ?? 0) * 200.0 + 120;
        highlightRect = Rect.fromLTWH(16, cardTop, size.width - 32, 60);
        break;
    }

    // Draw highlight background
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(8)),
      paint,
    );

    // Draw highlight border
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(8)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
