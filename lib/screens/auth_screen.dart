// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/auth_state.dart';
import '../utils/responsive_utils.dart';
import '../providers/accessibility_provider.dart';
import '../widgets/global_tts_overlay.dart';
import '../widgets/enhanced_accessible_text.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Login form controllers
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _loginFormKey = GlobalKey<FormState>();
  
  // Signup form controllers
  final _signupNameController = TextEditingController();
  final _signupEmailController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();
  final _signupFormKey = GlobalKey<FormState>();
  
  bool _isLoginLoading = false;
  bool _isSignupLoading = false;
  String? _loginError;
  String? _signupError;



  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Add tab change listener to read content when switching tabs
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Tab is changing, wait for it to complete
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            _readPageContent();
          }
        });
      }
    });
    
    // Auto-read page content when screen loads (similar to profile page)
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
        debugPrint('AuthScreen TTS: TTS is not enabled, skipping auto-read');
        return;
      }
      
      // Read only the relevant auth screen content, not the entire screen
      await readAuthScreenContent();
      
    } catch (e) {
      debugPrint('AuthScreen TTS Error: $e');
      // Don't rethrow the error to prevent screen from crashing
    }
  }

  /// Read only the auth screen content (similar to profile page approach)
  /// This method is public so it can be called by the TTS button
  Future<void> readAuthScreenContent() async {
    try {
      final accessibilityState = ref.read(accessibilityNotifierProvider);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

      // Only speak if TTS is enabled
      if (!accessibilityState.isTextToSpeechEnabled) {
        debugPrint('AuthScreen TTS: TTS is disabled, not speaking auth screen content');
        return;
      }
      
      // Build the text to read based on current tab
      final List<String> contentParts = [];
      
      // Add app title and branding
      contentParts.add('Welkom bij Karatapp');
      contentParts.add('Karate sportieve vechtkunst applicatie');
      
      // Get current tab index safely
      final currentTabIndex = _tabController.index;
      debugPrint('AuthScreen TTS: Current tab index: $currentTabIndex');
      
      if (currentTabIndex == 0) {
        // Login tab - comprehensive content reading
        contentParts.add('Inloggen pagina');
        contentParts.add('Welkom Terug titel');
        contentParts.add('Log in op je account instructie');
        contentParts.add('Voer je e-mailadres en wachtwoord in om in te loggen');
        
        // Add form field information
        contentParts.add('E-mail invoerveld: Voer je e-mailadres in');
        contentParts.add('Wachtwoord invoerveld: Voer je wachtwoord in, minimaal 6 tekens');
        
        // Add button information
        contentParts.add('Inloggen knop: Klik om in te loggen op je account');
        contentParts.add('Nog geen account tekst met Registreren knop om naar registratie te gaan');
        
        // Add error information if present
        if (_loginError != null) {
          contentParts.add('Foutmelding: $_loginError');
        }
        
        // Add loading state if present
        if (_isLoginLoading) {
          contentParts.add('Bezig met inloggen, even geduld');
        }
        
      } else if (currentTabIndex == 1) {
        // Signup tab - comprehensive content reading
        contentParts.add('Registreren pagina');
        contentParts.add('Account Aanmaken titel');
        contentParts.add('Word lid van de Karate gemeenschap beschrijving');
        contentParts.add('Voer je gegevens in om een nieuw account aan te maken');
        
        // Add form field information
        contentParts.add('Volledige Naam invoerveld: Voer je volledige naam in, minimaal 2 tekens');
        contentParts.add('E-mail invoerveld: Voer je e-mailadres in');
        contentParts.add('Wachtwoord invoerveld: Voer een wachtwoord in, minimaal 6 tekens');
        contentParts.add('Bevestig Wachtwoord invoerveld: Bevestig je wachtwoord');
        
        // Add button information
        contentParts.add('Account Aanmaken knop: Klik om een nieuw account te registreren');
        contentParts.add('Al een account tekst met Inloggen knop om naar inloggen te gaan');
        
        // Add error information if present
        if (_signupError != null) {
          contentParts.add('Foutmelding: $_signupError');
        }
        
        // Add loading state if present
        if (_isSignupLoading) {
          contentParts.add('Bezig met account aanmaken, even geduld');
        }
        
      } else {
        // Fallback for any other tab
        contentParts.add('Authenticatie pagina');
        contentParts.add('Log in of registreer je account');
        contentParts.add('Gebruik de tabs om te wisselen tussen inloggen en registreren');
      }
      
      // Add tab navigation information
      contentParts.add('Tab navigatie: Inloggen en Registreren tabs beschikbaar');
      contentParts.add('Gebruik de tabs om te wisselen tussen inloggen en registreren');
      
      final fullText = contentParts.join('. ');
      
      if (fullText.isNotEmpty) {
        debugPrint('AuthScreen TTS: Reading content: $fullText');
        
        // Stop any current speech
        if (accessibilityNotifier.isSpeaking()) {
          await accessibilityNotifier.stopSpeaking();
          await Future.delayed(const Duration(milliseconds: 300));
        }
        
        // Speak the auth screen content
        await accessibilityNotifier.speak(fullText);
      } else {
        debugPrint('AuthScreen TTS: No content to read');
      }
    } catch (e) {
      debugPrint('AuthScreen TTS Error: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _signupNameController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_loginFormKey.currentState!.validate()) return;
    
    setState(() {
      _isLoginLoading = true;
      _loginError = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
        _loginEmailController.text.trim(),
        _loginPasswordController.text,
      );
      
      // Navigate to home screen after successful login
      if (mounted && context.mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        // Intentionally do not show a popup here; login errors are handled in LoginScreen only
        FocusScope.of(context).unfocus();
        // Clear the global error to prevent duplicate display in AuthWrapper
        ref.read(authNotifierProvider.notifier).clearError();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoginLoading = false;
        });
      }
    }
  }

  Future<void> _signUp() async {
    if (!_signupFormKey.currentState!.validate()) return;
    
    setState(() {
      _isSignupLoading = true;
      _signupError = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signUp(
        _signupEmailController.text.trim(),
        _signupPasswordController.text,
        _signupNameController.text.trim(),
      );
      
      // Check if user is immediately authenticated (some signup flows auto-login)
      final authState = ref.read(authNotifierProvider);
      if (authState.isAuthenticated) {
        // Navigate to home screen if immediately authenticated
        if (mounted && context.mounted) {
          context.go('/home');
        }
      } else {
        // Show success message and switch to login tab
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account succesvol aangemaakt! Controleer je e-mail om je account te bevestigen.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
          
          // Switch to login tab
          _tabController.animateTo(0);
          
          // Pre-fill email in login form
          _loginEmailController.text = _signupEmailController.text;
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _signupError = e.toString();
        });
        // Clear the global error to prevent duplicate display in AuthWrapper
        ref.read(authNotifierProvider.notifier).clearError();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSignupLoading = false;
        });
      }
    }
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: context.responsiveValue(mobile: 40.0, tablet: 60.0, desktop: 80.0)),
            
            // App Logo/Title
            Semantics(
              label: 'Welkom Terug, titel van de inlogpagina',
              child: Text(
                'Welkom Terug',
                style: TextStyle(
                  fontSize: context.responsiveValue(mobile: 28.0, tablet: 32.0, desktop: 36.0),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
            Semantics(
              label: 'Log in op je account, instructie voor het inloggen',
              child: Text(
                'Log in op je account',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: context.responsiveValue(mobile: 40.0, tablet: 50.0, desktop: 60.0)),
            
            // Error message
            if (_loginError != null)
              Container(
                padding: context.responsivePadding,
                margin: EdgeInsets.only(bottom: context.responsiveSpacing(SpacingSize.md)),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: context.responsiveBorderRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        label: 'Foutmelding: $_loginError',
                        child: Text(
                          _loginError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Email field
            EnhancedAccessibleTextField(
              controller: _loginEmailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              customTTSLabel: 'E-mail invoerveld voor het inloggen',
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            
            // Password field
            EnhancedAccessibleTextField(
              controller: _loginPasswordController,
              decoration: const InputDecoration(
                labelText: 'Wachtwoord',
                prefixIcon: Icon(Icons.lock_outlined),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signIn(),
              customTTSLabel: 'Wachtwoord invoerveld voor het inloggen',
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.lg)),
            
            // Login button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoginLoading ? null : _signIn,
                child: _isLoginLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Semantics(
                        label: 'Inloggen knop om in te loggen op je account',
                        child: const Text('Inloggen'),
                      ),
              ),
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            
            // Switch to signup
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Nog geen account? Tekst om naar registratie te gaan',
                  child: Text(
                    'Nog geen account? ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: Semantics(
                    label: 'Registreren knop om een nieuw account aan te maken',
                    child: const Text('Registreren'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _signupFormKey,
      child: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: context.responsiveValue(mobile: 40.0, tablet: 50.0, desktop: 60.0)),
            
            // App Logo/Title
            Semantics(
              label: 'Account Aanmaken, titel van de registratiepagina',
              child: const Text(
                'Account Aanmaken',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Semantics(
              label: 'Word lid van de Karate gemeenschap, beschrijving van de registratie',
              child: Text(
                'Word lid van de Karate gemeenschap',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: context.responsiveValue(mobile: 40.0, tablet: 50.0, desktop: 60.0)),
            
            // Error message
            if (_signupError != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        label: 'Foutmelding: $_signupError',
                        child: Text(
                          _signupError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Name field
            EnhancedAccessibleTextField(
              controller: _signupNameController,
              decoration: const InputDecoration(
                labelText: 'Volledige Naam',
                prefixIcon: Icon(Icons.person_outlined),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              customTTSLabel: 'Volledige Naam invoerveld voor registratie',
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            
            // Email field
            EnhancedAccessibleTextField(
              controller: _signupEmailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              customTTSLabel: 'E-mail invoerveld voor registratie',
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            
            // Password field
            EnhancedAccessibleTextField(
              controller: _signupPasswordController,
              decoration: const InputDecoration(
                labelText: 'Wachtwoord',
                prefixIcon: Icon(Icons.lock_outlined),
                border: OutlineInputBorder(),
                helperText: 'Minimaal 6 tekens',
              ),
              obscureText: true,
              textInputAction: TextInputAction.next,
              customTTSLabel: 'Wachtwoord invoerveld voor registratie, minimaal 6 tekens',
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            
            // Confirm password field
            EnhancedAccessibleTextField(
              controller: _signupConfirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Bevestig Wachtwoord',
                prefixIcon: Icon(Icons.lock_outlined),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _signUp(),
              customTTSLabel: 'Bevestig Wachtwoord invoerveld voor registratie',
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.lg)),
            
            // Signup button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isSignupLoading ? null : _signUp,
                child: _isSignupLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Semantics(
                        label: 'Account Aanmaken knop om een nieuw account te registreren',
                        child: const Text('Account Aanmaken'),
                      ),
              ),
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            
            // Switch to login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Al een account? Tekst om naar inloggen te gaan',
                  child: Text(
                    'Al een account? ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(0),
                  child: Semantics(
                    label: 'Inloggen knop om naar de inlogpagina te gaan',
                    child: const Text('Inloggen'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes for automatic navigation
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.isAuthenticated && mounted && context.mounted) {
        // Navigate to home screen when user becomes authenticated
        context.go('/home');
      }
    });
    
    return GlobalTTSOverlay(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
            // App branding
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // App icon or logo could go here
                  Semantics(
                    label: 'Karate app logo, sportieve vechtkunst icoon',
                    child: Icon(
                      Icons.sports_martial_arts,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
                  Semantics(
                    label: 'Karatapp, naam van de applicatie',
                    child: Text(
                      'Karatapp',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Semantics(
                      label: 'Inloggen tab, klik om naar de inlogpagina te gaan',
                      child: const Text('Inloggen'),
                    ),
                  ),
                  Tab(
                    child: Semantics(
                      label: 'Registreren tab, klik om naar de registratiepagina te gaan',
                      child: const Text('Registreren'),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginForm(),
                  _buildSignupForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
