// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_layout.dart';

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
      
      // Navigation will be handled automatically by the router
      // since it watches the auth state changes
    } catch (e) {
      if (mounted) {
        setState(() {
          _loginError = e.toString();
        });
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
    } catch (e) {
      if (mounted) {
        setState(() {
          _signupError = e.toString();
        });
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
            Text(
              'Welkom Terug',
              style: TextStyle(
                fontSize: context.responsiveValue(mobile: 28.0, tablet: 32.0, desktop: 36.0),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
            Text(
              'Log in op je account',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
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
                      child: Text(
                        _loginError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Email field
            TextFormField(
              controller: _loginEmailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Voer je e-mailadres in';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Voer een geldig e-mailadres in';
                }
                return null;
              },
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            
            // Password field
            TextFormField(
              controller: _loginPasswordController,
              decoration: const InputDecoration(
                labelText: 'Wachtwoord',
                prefixIcon: Icon(Icons.lock_outlined),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signIn(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Voer je wachtwoord in';
                }
                if (value.length < 6) {
                  return 'Wachtwoord moet minimaal 6 tekens zijn';
                }
                return null;
              },
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
                    : const Text('Inloggen'),
              ),
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            
            // Switch to signup
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Nog geen account? ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('Registreren'),
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
            const Text(
              'Account Aanmaken',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Word lid van de Karate gemeenschap',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
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
                      child: Text(
                        _signupError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Name field
            TextFormField(
              controller: _signupNameController,
              decoration: const InputDecoration(
                labelText: 'Volledige Naam',
                prefixIcon: Icon(Icons.person_outlined),
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Voer je volledige naam in';
                }
                if (value.trim().length < 2) {
                  return 'Naam moet minimaal 2 tekens zijn';
                }
                return null;
              },
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            
            // Email field
            TextFormField(
              controller: _signupEmailController,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Voer je e-mailadres in';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Voer een geldig e-mailadres in';
                }
                return null;
              },
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            
            // Password field
            TextFormField(
              controller: _signupPasswordController,
              decoration: const InputDecoration(
                labelText: 'Wachtwoord',
                prefixIcon: Icon(Icons.lock_outlined),
                border: OutlineInputBorder(),
                helperText: 'Minimaal 6 tekens',
              ),
              obscureText: true,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Voer een wachtwoord in';
                }
                if (value.length < 6) {
                  return 'Wachtwoord moet minimaal 6 tekens zijn';
                }
                return null;
              },
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            
            // Confirm password field
            TextFormField(
              controller: _signupConfirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Bevestig Wachtwoord',
                prefixIcon: Icon(Icons.lock_outlined),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _signUp(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Bevestig je wachtwoord';
                }
                if (value != _signupPasswordController.text) {
                  return 'Wachtwoorden komen niet overeen';
                }
                return null;
              },
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
                    : const Text('Account Aanmaken'),
              ),
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            
            // Switch to login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Al een account? ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(0),
                      child: const Text('Inloggen'),
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // App branding
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // App icon or logo could go here
                  Icon(
                    Icons.sports_martial_arts,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
                  Text(
                    'Karatapp',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
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
                tabs: const [
                  Tab(text: 'Inloggen'),
                  Tab(text: 'Registreren'),
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
    );
  }
}
