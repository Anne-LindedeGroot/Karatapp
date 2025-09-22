import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/accessibility_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/kata_provider.dart';

/// Enhanced TTS Menu Widget that speaks entire menu items
class EnhancedTTSMenuWidget extends ConsumerWidget {
  final String currentRoute;
  final VoidCallback? onMenuItemSpoken;

  const EnhancedTTSMenuWidget({
    super.key,
    required this.currentRoute,
    this.onMenuItemSpoken,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final currentUser = ref.watch(authUserProvider);

    if (!accessibilityState.isTextToSpeechEnabled) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.record_voice_over,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Menu Voorlezen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Menu items with TTS
          _buildMenuSection(
            context,
            ref,
            'Hoofdmenu',
            [
              _MenuItemData(
                icon: Icons.home,
                title: 'Hoofdpagina',
                description: 'Bekijk alle kata\'s, zoek en voeg nieuwe toe',
                route: '/home',
                isActive: currentRoute == '/home' || currentRoute == '/',
              ),
              _MenuItemData(
                icon: Icons.person,
                title: 'Profiel',
                description: 'Bekijk en bewerk je profiel informatie',
                route: '/profile',
                isActive: currentRoute == '/profile',
              ),
              _MenuItemData(
                icon: Icons.favorite,
                title: 'Favorieten',
                description: 'Je opgeslagen favoriete kata\'s',
                route: '/favorites',
                isActive: currentRoute == '/favorites',
              ),
              _MenuItemData(
                icon: Icons.forum,
                title: 'Community Forum',
                description: 'Deel ervaringen en stel vragen aan andere gebruikers',
                route: '/forum',
                isActive: currentRoute == '/forum',
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Quick actions section
          _buildMenuSection(
            context,
            ref,
            'Snelle Acties',
            [
              _MenuItemData(
                icon: Icons.add,
                title: 'Nieuwe Kata Toevoegen',
                description: 'Maak een nieuwe kata aan met afbeeldingen en video\'s',
                action: () => _showAddKataDialog(context),
                isAction: true,
              ),
              _MenuItemData(
                icon: Icons.refresh,
                title: 'Kata\'s Verversen',
                description: 'Herlaad alle kata\'s van de server',
                action: () => _refreshKatas(context, ref),
                isAction: true,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // User info section
          _buildUserInfoSection(context, ref, currentUser),
          
          const SizedBox(height: 16),
          
          // Page reading controls
          _buildPageReadingControls(context, ref),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    WidgetRef ref,
    String sectionTitle,
    List<_MenuItemData> items,
  ) {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => accessibilityNotifier.speak('$sectionTitle sectie'),
          child: Text(
            sectionTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _buildMenuItem(context, ref, item)),
      ],
    );
  }

  Widget _buildMenuItem(BuildContext context, WidgetRef ref, _MenuItemData item) {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: item.isActive 
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
          : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            // Speak the menu item
            final speechText = '${item.title}. ${item.description}';
            await accessibilityNotifier.speak(speechText);
            
            // Execute action or navigate
            if (item.isAction && item.action != null) {
              item.action!();
            } else if (item.route != null) {
              if (context.mounted) {
                context.go(item.route!);
              }
            }
            
            onMenuItemSpoken?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: item.isActive
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: item.isActive ? FontWeight.bold : FontWeight.w500,
                          color: item.isActive
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.volume_up,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfoSection(BuildContext context, WidgetRef ref, dynamic currentUser) {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    final userName = currentUser?.userMetadata?['full_name'] ?? 
                    currentUser?.email ?? 
                    'Gebruiker';
    
    return GestureDetector(
      onTap: () => accessibilityNotifier.speak('Ingelogd als $userName'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 18,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingelogd als',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.volume_up,
              size: 16,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageReadingControls(BuildContext context, WidgetRef ref) {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pagina Voorlezen',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _readEntirePage(context, ref),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Hele Pagina'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => accessibilityNotifier.stopSpeaking(),
                icon: const Icon(Icons.stop, size: 18),
                label: const Text('Stop'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddKataDialog(BuildContext context) {
    // Show a simple snackbar message for now
    // In a real implementation, you would use a callback or state management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Nieuwe kata toevoegen functie - gebruik de + knop in de app'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _refreshKatas(BuildContext context, WidgetRef ref) {
    // Trigger kata refresh using the provider
    ref.read(kataNotifierProvider.notifier).refreshKatas();
  }

  void _readEntirePage(BuildContext context, WidgetRef ref) async {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Generate comprehensive page content based on current route
    String pageContent = _generateComprehensivePageContent(currentRoute);
    
    await accessibilityNotifier.speak(pageContent);
  }

  String _generateComprehensivePageContent(String route) {
    switch (route) {
      case '/':
      case '/home':
        return 'Welkom op de hoofdpagina van Karatapp. '
               'Hier kun je alle kata\'s bekijken en beheren. '
               'Gebruik de zoekbalk om specifieke kata\'s te vinden. '
               'Druk op de plus knop om een nieuwe kata toe te voegen. '
               'In het menu vind je toegang tot je profiel, favorieten, en het community forum. '
               'Gebruik de toegankelijkheids knoppen om de tekst grootte aan te passen en spraak in te stellen.';
      
      case '/profile':
        return 'Je bent op de profiel pagina. '
               'Hier kun je je persoonlijke informatie bekijken en bewerken. '
               'Je kunt je avatar wijzigen, je naam aanpassen, en andere profiel instellingen beheren. '
               'Gebruik het menu om terug te gaan naar de hoofdpagina of andere secties.';
      
      case '/favorites':
        return 'Dit is je favorieten pagina. '
               'Hier vind je alle kata\'s die je als favoriet hebt gemarkeerd. '
               'Je kunt favorieten toevoegen door op het hart icoon te drukken bij een kata. '
               'Gebruik het menu om naar andere secties te navigeren.';
      
      case '/forum':
        return 'Welkom bij het community forum. '
               'Hier kun je berichten lezen en plaatsen om te communiceren met andere gebruikers. '
               'Deel je ervaringen, stel vragen, en leer van anderen in de karate gemeenschap. '
               'Gebruik de knoppen om nieuwe berichten te maken of bestaande berichten te bekijken.';
      
      default:
        return 'Je bent op een pagina van Karatapp. '
               'Gebruik het menu om te navigeren naar verschillende secties van de app. '
               'De toegankelijkheids functies helpen je bij het gebruik van de app.';
    }
  }
}

/// Data class for menu items
class _MenuItemData {
  final IconData icon;
  final String title;
  final String description;
  final String? route;
  final VoidCallback? action;
  final bool isActive;
  final bool isAction;

  const _MenuItemData({
    required this.icon,
    required this.title,
    required this.description,
    this.route,
    this.action,
    this.isActive = false,
    this.isAction = false,
  });
}

/// Enhanced TTS Floating Action Button
class EnhancedTTSFloatingButton extends ConsumerStatefulWidget {
  final String currentRoute;

  const EnhancedTTSFloatingButton({
    super.key,
    required this.currentRoute,
  });

  @override
  ConsumerState<EnhancedTTSFloatingButton> createState() => _EnhancedTTSFloatingButtonState();
}

class _EnhancedTTSFloatingButtonState extends ConsumerState<EnhancedTTSFloatingButton>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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
    final accessibilityState = ref.watch(accessibilityNotifierProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Expanded menu
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: _isExpanded
                  ? Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: SingleChildScrollView(
                        child: EnhancedTTSMenuWidget(
                          currentRoute: widget.currentRoute,
                          onMenuItemSpoken: () {
                            setState(() {
                              _isExpanded = false;
                              _animationController.reverse();
                            });
                          },
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            );
          },
        ),
        
        if (_isExpanded) const SizedBox(height: 16),
        
        // Main FAB
        FloatingActionButton(
          onPressed: _toggleExpanded,
          backgroundColor: accessibilityState.isTextToSpeechEnabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.secondary,
          foregroundColor: accessibilityState.isTextToSpeechEnabled
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSecondary,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              _isExpanded ? Icons.close : Icons.record_voice_over,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}
