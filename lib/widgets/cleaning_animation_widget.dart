import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/kata_provider.dart';
import '../utils/responsive_utils.dart';
import 'global_tts_overlay.dart';

/// Animated cleaning widget that shows visual feedback during cleanup process
class CleaningAnimationWidget extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;
  final VoidCallback? onError;

  const CleaningAnimationWidget({
    super.key,
    this.onComplete,
    this.onError,
  });

  @override
  ConsumerState<CleaningAnimationWidget> createState() => _CleaningAnimationWidgetState();
}

class _CleaningAnimationWidgetState extends ConsumerState<CleaningAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _broomController;
  late AnimationController _trashController;
  late AnimationController _sparkleController;
  late Animation<double> _broomAnimation;
  late Animation<double> _trashAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _broomController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _trashController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Create animations
    _broomAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _broomController,
      curve: Curves.elasticOut,
    ));

    _trashAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _trashController,
      curve: Curves.bounceOut,
    ));

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _startCleaningAnimation();
  }

  void _startCleaningAnimation() async {
    if (!mounted) return;
    
    try {
      // Start broom animation
      _broomController.forward();
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!mounted) return;
      
      // Start trash animation
      _trashController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (!mounted) return;
      
      // Start sparkle animation
      _sparkleController.forward();
    } catch (e) {
      // Handle any animation errors gracefully
      debugPrint('Animation error: $e');
    }
  }

  @override
  void dispose() {
    _broomController.dispose();
    _trashController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DialogTTSOverlay(
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: context.isTablet ? 400 : 300,
            maxHeight: context.isTablet ? 500 : 400,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated cleaning icons
              SizedBox(
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Broom animation
                    AnimatedBuilder(
                      animation: _broomAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _broomAnimation.value,
                          child: Transform.rotate(
                            angle: _broomAnimation.value * 0.3,
                            child: Icon(
                              Icons.cleaning_services,
                              size: 60,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Trash animation
                    AnimatedBuilder(
                      animation: _trashAnimation,
                      builder: (context, child) {
                        return Positioned(
                          right: 20 + (_trashAnimation.value * 30),
                          top: 40 - (_trashAnimation.value * 20),
                          child: Transform.scale(
                            scale: _trashAnimation.value,
                            child: Icon(
                              Icons.delete_outline,
                              size: 40,
                              color: Colors.red.shade500,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Sparkle effects
                    AnimatedBuilder(
                      animation: _sparkleAnimation,
                      builder: (context, child) {
                        return Positioned(
                          left: 30,
                          top: 20,
                          child: Opacity(
                            opacity: _sparkleAnimation.value,
                            child: Icon(
                              Icons.auto_awesome,
                              size: 24,
                              color: Colors.amber.shade400,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Loading text
              Text(
                'Bezig met opruimen...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Progress indicator
              const LinearProgressIndicator(
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enhanced cleaning popup with better Dutch messaging and responsive design
class CleaningResultDialog extends StatelessWidget {
  final int cleanedCount;
  final bool hasError;
  final String? errorMessage;

  const CleaningResultDialog({
    super.key,
    required this.cleanedCount,
    this.hasError = false,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return DialogTTSOverlay(
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: context.isTablet ? 450 : 350,
            maxHeight: context.isTablet ? 400 : 300,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Result icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasError 
                    ? Colors.red.shade50
                    : cleanedCount > 0 
                      ? Colors.green.shade50 
                      : Colors.blue.shade50,
                ),
                child: Icon(
                  hasError 
                    ? Icons.error_outline
                    : cleanedCount > 0 
                      ? Icons.check_circle_outline
                      : Icons.cleaning_services,
                  size: 40,
                  color: hasError 
                    ? Colors.red.shade600
                    : cleanedCount > 0 
                      ? Colors.green.shade600 
                      : Colors.blue.shade600,
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Title
              Text(
                hasError 
                  ? 'Fout bij opruimen'
                  : cleanedCount > 0 
                    ? 'Opruimen voltooid!'
                    : 'Alles is al schoon',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: hasError 
                    ? Colors.red.shade700
                    : cleanedCount > 0 
                      ? Colors.green.shade700 
                      : Colors.blue.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 12),
              
              // Message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  hasError 
                    ? errorMessage ?? 'Er is een onverwachte fout opgetreden tijdens het opruimen.'
                    : cleanedCount > 0 
                      ? '$cleanedCount verweesde afbeelding${cleanedCount == 1 ? '' : 'en'} succesvol opgeruimd. Je opslag is nu schoon!'
                      : 'Er zijn geen verweesde afbeeldingen gevonden. Je opslag is al schoon en georganiseerd!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasError 
                      ? Colors.red.shade600
                      : cleanedCount > 0 
                        ? Colors.green.shade600 
                        : Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Enhanced cleaning function with animations and better popup handling
class EnhancedCleaningService {
  static Future<void> performCleaningWithAnimation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    // Check if context is still valid before showing dialog
    if (!context.mounted) return;
    
    // Show animated cleaning dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CleaningAnimationWidget(),
    );

    try {
      // Perform the actual cleaning (now much safer)
      final deletedPaths = await ref
          .read(kataNotifierProvider.notifier)
          .safeCleanupTempFolders();

      // Close the animation dialog with safety checks
      if (context.mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          debugPrint('Error closing animation dialog: $e');
        }
      }

      // Show result dialog with safety checks
      if (context.mounted) {
        try {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => CleaningResultDialog(
              cleanedCount: deletedPaths.length,
            ),
          );
        } catch (e) {
          debugPrint('Error showing result dialog: $e');
        }
      }
    } catch (e) {
      // Close the animation dialog with safety checks
      if (context.mounted) {
        try {
          Navigator.of(context).pop();
        } catch (e) {
          debugPrint('Error closing animation dialog on error: $e');
        }
      }

      // Show error dialog with safety checks
      if (context.mounted) {
        try {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => CleaningResultDialog(
              cleanedCount: 0,
              hasError: true,
              errorMessage: 'Fout tijdens opruimen: $e',
            ),
          );
        } catch (e) {
          debugPrint('Error showing error dialog: $e');
        }
      }
    }
  }
}
