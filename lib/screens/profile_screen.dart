import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/accessibility_provider.dart';
import '../providers/role_provider.dart';
import '../providers/data_usage_provider.dart';
import '../providers/network_provider.dart';
import '../services/role_service.dart';
import '../services/auth_service.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/accessible_text.dart';
import '../utils/responsive_utils.dart';
import '../core/navigation/app_router.dart';
import 'avatar_selection_screen.dart';
import 'data_usage_settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();
  String? _successMessage;
  bool _isNameFieldFocused = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Pre-fill the name field with current user's name if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(authUserProvider);
      if (currentUser != null) {
        _nameController.text =
            currentUser.userMetadata?['full_name']?.toString() ?? '';
      }
    });

    // Add focus listener to track when the name field is focused
    _nameFocusNode.addListener(() {
      setState(() {
        _isNameFieldFocused = _nameFocusNode.hasFocus;
      });
    });

    // Add text controller listener to rebuild when text changes
    _nameController.addListener(() {
      setState(() {
        // This will trigger a rebuild when text changes
      });
    });

    // Auto-read page content when screen loads (similar to logout popup)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readPageContent();
    });
  }

  /// Read the current page content using TTS
  Future<void> _readPageContent() async {
    try {
      // Add a small delay to ensure the screen is fully rendered
      await Future.delayed(const Duration(milliseconds: 500));
      
      final accessibilityState = ref.read(accessibilityNotifierProvider);
      
      // Only proceed if TTS is enabled
      if (!accessibilityState.isTextToSpeechEnabled) {
        debugPrint('ProfileScreen TTS: TTS is not enabled, skipping auto-read');
        return;
      }
      
      // Read only the relevant profile screen content, not the entire screen
      await _readProfileScreenContent();
      
    } catch (e) {
      debugPrint('ProfileScreen TTS Error: $e');
      // Don't rethrow the error to prevent screen from crashing
    }
  }

  /// Read only the profile screen content (similar to logout popup approach)
  Future<void> _readProfileScreenContent() async {
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      final currentUser = ref.read(authUserProvider);
      
      // Build the text to read
      final List<String> contentParts = [];
      
      // Add page title
      contentParts.add('Profiel pagina');
      contentParts.add('Gebruikersprofiel');
      
      // Add user info
      if (currentUser?.email != null) {
        contentParts.add('E-mail: ${currentUser!.email}');
      }
      
      // Add role info
      final userRoleAsync = ref.read(currentUserRoleProvider);
      userRoleAsync.when(
        data: (role) {
          contentParts.add('Rol: ${role.displayName}');
          contentParts.add('Beschrijving: ${role.description}');
        },
        loading: () => contentParts.add('Rol wordt geladen'),
        error: (_, __) => contentParts.add('Fout bij laden rol'),
      );
      
      // Add name info
      if (currentUser?.userMetadata?['full_name'] != null) {
        contentParts.add('Volledige naam: ${currentUser!.userMetadata!['full_name']}');
      } else {
        contentParts.add('Volledige naam: Niet ingesteld');
      }
      
      // Add accessibility settings
      final accessibilityState = ref.read(accessibilityNotifierProvider);
      contentParts.add('Toegankelijkheid: Spraakknop ${accessibilityState.showTTSButton ? 'zichtbaar' : 'verborgen'}');
      
      // Add data usage info
      final dataUsageState = ref.read(dataUsageProvider);
      final networkState = ref.read(networkProvider);
      contentParts.add('Netwerkstatus: ${networkState.isConnected ? 'Verbonden' : 'Niet verbonden'}');
      contentParts.add('Dataverbruik modus: ${_getDataUsageModeText(dataUsageState.mode)}');
      contentParts.add('Maandelijks verbruik: ${dataUsageState.stats.formattedTotalUsage} van ${dataUsageState.monthlyDataLimit} MB');
      
      final fullText = contentParts.join('. ');
      
      if (fullText.isNotEmpty) {
        debugPrint('ProfileScreen TTS: Reading content: $fullText');
        
        // Stop any current speech
        if (accessibilityNotifier.isSpeaking()) {
          await accessibilityNotifier.stopSpeaking();
          await Future.delayed(const Duration(milliseconds: 300));
        }
        
        // Speak the profile screen content
        await accessibilityNotifier.speak(fullText);
      } else {
        debugPrint('ProfileScreen TTS: No content to read');
      }
    } catch (e) {
      debugPrint('ProfileScreen TTS Error: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voer een naam in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Clear any previous errors
    ref.read(authNotifierProvider.notifier).clearError();

    try {
      await ref
          .read(authNotifierProvider.notifier)
          .updateUserName(_nameController.text.trim());

      setState(() {
        _successMessage = 'Naam succesvol bijgewerkt!';
      });

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Naam succesvol bijgewerkt!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Clear success message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } catch (e) {
      // Error is handled by the provider and will be displayed in the UI
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij bijwerken naam: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    // Speak the action once when button is pressed
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Account verwijderen gestart. Bevestigingsdialoog wordt getoond.');
    } catch (e) {
      // Ignore TTS errors
    }

    // Show confirmation dialog
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Account verwijderen'),
          content: SingleChildScrollView(
            child: Text(
              'Weet je zeker dat je je account wilt verwijderen? Dit zal alle je gegevens permanent verwijderen en kan niet ongedaan worden gemaakt.',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Verwijderen'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      // Speak cancellation message
      try {
        final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
        await accessibilityNotifier.speak('Account verwijderen geannuleerd.');
      } catch (e) {
        // Ignore TTS errors
      }
      return;
    }

    // Speak confirmation for second dialog
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Laatste bevestiging vereist. Wees voorzichtig, dit kan niet ongedaan worden gemaakt.');
    } catch (e) {
      // Ignore TTS errors
    }

    // Show second confirmation dialog
    if (!mounted) return;
    final finalConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Laatste waarschuwing'),
          content: SingleChildScrollView(
            child: Text(
              'Dit is je laatste kans om te annuleren. Klik op "Verwijder mijn account" om je account definitief te verwijderen.',
              style: const TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Ik begrijp het, verwijder mijn account'),
            ),
          ],
        );
      },
    );

    if (finalConfirmed != true) {
      // Speak final cancellation message
      try {
        final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
        await accessibilityNotifier.speak('Account verwijderen definitief geannuleerd.');
      } catch (e) {
        // Ignore TTS errors
      }
      return;
    }

    // Check if user is still authenticated before starting deletion
    final currentUser = ref.read(authUserProvider);
    if (currentUser == null) {
      // Speak error message
      try {
        final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
        await accessibilityNotifier.speak('Je bent niet ingelogd. Log eerst in om je account te verwijderen.');
      } catch (e) {
        // Ignore TTS errors
      }
      
      // Show error message and navigate to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Je bent niet ingelogd. Log eerst in om je account te verwijderen.'),
            backgroundColor: Colors.red,
          ),
        );
        context.go('/login');
      }
      return;
    }

    try {
      // Speak deletion start message
      try {
        final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
        await accessibilityNotifier.speak('Account wordt nu verwijderd. Dit kan even duren.');
      } catch (e) {
        // Ignore TTS errors
      }

      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    'Account wordt verwijderd...',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          );
        },
      );

      // Delete the account
      await _authService.deleteAccount();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Speak success message
      try {
        final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
        await accessibilityNotifier.speak('Account succesvol verwijderd. Je wordt doorgestuurd naar het inlogscherm.');
      } catch (e) {
        // Ignore TTS errors
      }

      // Show success message and navigate to login
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Je account is succesvol verwijderd. Je wordt doorgestuurd naar het inlogscherm.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to login screen
        context.go('/login');
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      // Speak error message
      try {
        final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
        await accessibilityNotifier.speak('Fout bij verwijderen account. Probeer het opnieuw.');
      } catch (e) {
        // Ignore TTS errors
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij verwijderen account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final currentUser = authState.user;
    final isLoading = authState.isLoading;
    final errorMessage = authState.error;

    return Scaffold(
      appBar: AppBar(
        title: const AccessibleText(
          'Profiel',
          enableTextToSpeech: true,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goBackOrHome(),
        ),
        actions: [
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          // Remove focus from any text field when tapping outside
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: context.responsivePadding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  kToolbarHeight -
                  32, // 32 for padding
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  'Gebruikersprofiel',
                  style: TextStyle(
                    fontSize: context.responsiveValue(mobile: 24.0, tablet: 28.0, desktop: 32.0),
                    fontWeight: FontWeight.bold,
                  ),
                  enableTextToSpeech: true,
                ),
                SizedBox(height: context.responsiveValue(mobile: 30.0, tablet: 40.0, desktop: 50.0)),
                // Avatar Section
                Center(
                  child: AvatarWidget(
                    avatarId: currentUser?.userMetadata?['avatar_id']
                        ?.toString(),
                    customAvatarUrl: currentUser?.userMetadata?['avatar_url']
                        ?.toString(),
                    userName:
                        currentUser?.userMetadata?['full_name']?.toString() ??
                        currentUser?.email,
                    size: context.responsiveValue(mobile: 120.0, tablet: 140.0, desktop: 160.0),
                    showEditIcon: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AvatarSelectionScreen(),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: context.responsiveValue(mobile: 30.0, tablet: 40.0, desktop: 50.0)),
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: context.responsiveBorderRadius,
                    ),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: context.responsiveBorderRadius,
                    ),
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                const AccessibleText(
                  'E-mail',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  enableTextToSpeech: true,
                ),
                AccessibleText(
                  currentUser?.email ?? 'Onbekend',
                  style: const TextStyle(fontSize: 16),
                  enableTextToSpeech: true,
                ),
                SizedBox(height: context.responsiveSpacing(SpacingSize.lg)),
                // Role Section
                const AccessibleText(
                  'Rol',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  enableTextToSpeech: true,
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final userRoleAsync = ref.watch(currentUserRoleProvider);

                    return userRoleAsync.when(
                      data: (role) {
                        Color roleColor;
                        IconData roleIcon;

                        switch (role) {
                          case UserRole.host:
                            roleColor = Colors.purple;
                            roleIcon = Icons.admin_panel_settings;
                            break;
                          case UserRole.mediator:
                            roleColor = Colors.orange;
                            roleIcon = Icons.shield;
                            break;
                          case UserRole.user:
                            roleColor = Colors.blue;
                            roleIcon = Icons.person;
                            break;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(context.responsiveValue(mobile: 20.0, tablet: 24.0, desktop: 28.0)),
                            border: Border.all(
                              color: roleColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(roleIcon, color: roleColor, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: AccessibleText(
                                  role.displayName,
                                  style: TextStyle(
                                    color: roleColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  enableTextToSpeech: true,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loading: () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(context.responsiveValue(mobile: 20.0, tablet: 24.0, desktop: 28.0)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            AccessibleText(
                              'Rol laden...',
                              enableTextToSpeech: true,
                            ),
                          ],
                        ),
                      ),
                      error: (error, stack) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(context.responsiveValue(mobile: 20.0, tablet: 24.0, desktop: 28.0)),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            const AccessibleText(
                              'Fout bij laden rol',
                              style: TextStyle(color: Colors.red, fontSize: 14),
                              enableTextToSpeech: true,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
                // Role description
                Consumer(
                  builder: (context, ref, child) {
                    final userRoleAsync = ref.watch(currentUserRoleProvider);

                    return userRoleAsync.when(
                      data: (role) => AccessibleText(
                        role.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        enableTextToSpeech: true,
                      ),
                      loading: () => const SizedBox.shrink(),
                      error: (error, stack) => const SizedBox.shrink(),
                    );
                  },
                ),
                SizedBox(height: context.responsiveSpacing(SpacingSize.lg)),
                const AccessibleText(
                  'Volledige naam',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  enableTextToSpeech: true,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        decoration: InputDecoration(
                          labelText: _isNameFieldFocused
                              ? 'Voer uw volledige naam in'
                              : null,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4), // Reduced from 8 to 4
                    SizedBox(
                      height: 56, // Match TextField height
                      child: const SizedBox.shrink(),
                    ),
                  ],
                ),
                SizedBox(height: context.responsiveSpacing(SpacingSize.lg)),
                // Show update button only when:
                // 1. Field is focused (editing), OR
                // 2. There's no name in the text field
                if (_isNameFieldFocused || _nameController.text.trim().isEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _updateName,
                      child: isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              _nameController.text.trim().isEmpty
                                  ? 'Naam toevoegen'
                                  : 'Naam bijwerken',
                            ),
                    ),
                  ),

                SizedBox(height: context.responsiveValue(mobile: 30.0, tablet: 40.0, desktop: 50.0)),
                
                // TTS Button Visibility Toggle
                const AccessibleText(
                  'Toegankelijkheid',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  enableTextToSpeech: true,
                ),
                SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
                
                // TTS Button Visibility Toggle
                Consumer(
                  builder: (context, ref, child) {
                    final accessibilityState = ref.watch(accessibilityNotifierProvider);
                    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
                    
                    return Card(
                      child: SwitchListTile(
                        title: const AccessibleText(
                          'Spraakknop weergeven',
                          enableTextToSpeech: true,
                        ),
                        subtitle: const AccessibleText(
                          'Toon of verberg de spraakknop op alle schermen',
                          enableTextToSpeech: true,
                        ),
                        value: accessibilityState.showTTSButton,
                        onChanged: (value) {
                          accessibilityNotifier.setShowTTSButton(value);
                        },
                        secondary: Icon(
                          accessibilityState.showTTSButton 
                            ? Icons.headphones 
                            : Icons.headphones_outlined,
                          color: accessibilityState.showTTSButton 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: context.responsiveValue(mobile: 30.0, tablet: 40.0, desktop: 50.0)),
                
                // Data Usage Settings Section
                const AccessibleText(
                  'Dataverbruik & Offline',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  enableTextToSpeech: true,
                ),
                SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
                
                // Data Usage Status Card
                Consumer(
                  builder: (context, ref, child) {
                    final dataUsageState = ref.watch(dataUsageProvider);
                    final networkState = ref.watch(networkProvider);
                    
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  networkState.isConnected ? Icons.wifi : Icons.wifi_off,
                                  color: networkState.isConnected ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                const AccessibleText(
                                  'Netwerkstatus',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  enableTextToSpeech: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Connection Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: AccessibleText(
                                    'Status:',
                                    enableTextToSpeech: true,
                                  ),
                                ),
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced horizontal padding
                                    decoration: BoxDecoration(
                                      color: networkState.isConnected 
                                          ? Colors.green.withValues(alpha: 0.1) 
                                          : Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: AccessibleText(
                                      networkState.isConnected ? 'Verbonden' : 'Niet verbonden',
                                      style: TextStyle(
                                        color: networkState.isConnected ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      enableTextToSpeech: true,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Data Usage Mode
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: AccessibleText(
                                    'Dataverbruik modus:',
                                    enableTextToSpeech: true,
                                  ),
                                ),
                                Flexible(
                                  child: AccessibleText(
                                    _getDataUsageModeText(dataUsageState.mode),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                    enableTextToSpeech: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Monthly Usage
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Flexible(
                                  child: AccessibleText(
                                    'Maandelijks verbruik:',
                                    enableTextToSpeech: true,
                                  ),
                                ),
                                Flexible(
                                  child: AccessibleText(
                                    '${dataUsageState.stats.formattedTotalUsage} / ${dataUsageState.monthlyDataLimit} MB',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                    enableTextToSpeech: true,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            
                            // Usage Progress Bar
                            if (dataUsageState.monthlyDataLimit > 0) ...[
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: (dataUsageState.stats.totalBytesUsed / (1024 * 1024)) / dataUsageState.monthlyDataLimit,
                                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  dataUsageState.shouldShowDataWarning ? Colors.red : Colors.green,
                                ),
                              ),
                            ],
                            
                            // Data Warning
                            if (dataUsageState.shouldShowDataWarning) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.orange, size: 16),
                                    SizedBox(width: 6), // Reduced from 8 to 6
                                    Expanded(
                                      child: AccessibleText(
                                        'Nadert maandelijks dataverbruik limiet',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        enableTextToSpeech: true,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 16),
                            
                            // Settings Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const DataUsageSettingsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.settings, size: 18),
                                label: const AccessibleText(
                                  'Dataverbruik instellingen',
                                  enableTextToSpeech: true,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                  minimumSize: const Size(double.infinity, 48),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: context.responsiveValue(mobile: 30.0, tablet: 40.0, desktop: 50.0)),
                
                // Account Deletion Section
                const AccessibleText(
                  'Account beheer',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  enableTextToSpeech: true,
                ),
                SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
                
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gevaarlijke acties',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Deze acties kunnen niet ongedaan worden gemaakt.',
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _deleteAccount,
                            icon: const Icon(Icons.delete_forever, size: 18),
                            label: const Text('Account verwijderen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: context.responsiveValue(mobile: 30.0, tablet: 40.0, desktop: 50.0)),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// Get Dutch text for data usage mode
  String _getDataUsageModeText(DataUsageMode mode) {
    switch (mode) {
      case DataUsageMode.unlimited:
        return 'Onbeperkt';
      case DataUsageMode.moderate:
        return 'Gematigd';
      case DataUsageMode.strict:
        return 'Strikt';
      case DataUsageMode.wifiOnly:
        return 'Alleen Wi-Fi';
    }
  }
}
