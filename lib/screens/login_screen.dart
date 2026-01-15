// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../core/navigation/scaffold_messenger.dart';
import '../core/navigation/app_router.dart';
import '../utils/responsive_utils.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static final Pattern _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$'); // ignore: deprecated_member_use

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  String _mapLoginErrorToDutch(String raw) {
    final e = raw.toLowerCase();
    if (e.contains('e-mailadres of wachtwoord is onjuist') || e.contains('invalid email or password')) {
      return 'E-mailadres of wachtwoord is onjuist. Opnieuw proberen.';
    }
    if (e.contains('verbinding') || e.contains('network') || e.contains('connection') || e.contains('timeout') || e.contains('socket')) {
      return 'Verbindingsprobleem. Controleer je internet en probeer opnieuw.';
    }
    if (e.contains('te veel') || e.contains('too many requests') || e.contains('429')) {
      return 'Te veel pogingen. Wacht even en probeer opnieuw.';
    }
    if (e.contains('server')) {
      return 'Serverfout. Probeer het later opnieuw.';
    }
    return 'Verkeerde logininformatie. Opnieuw proberen.';
  }

  void _showLoginErrorDialog(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dialogContext = rootScaffoldMessengerKey.currentContext ?? context;
      showDialog(
        context: dialogContext,
        useRootNavigator: true,
        builder: (ctx) => AlertDialog(
          title: const Text('Fout'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authNotifierProvider.notifier).signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      
      // Navigation will be handled automatically by AuthWrapper
      // since it watches the auth state changes
    } catch (e) {
      if (mounted) {
        final message = _mapLoginErrorToDutch(e.toString());
        FocusScope.of(context).unfocus();
        _showLoginErrorDialog(message);
        // Clear the global error to prevent duplicate display elsewhere
        ref.read(authNotifierProvider.notifier).clearError();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inloggen'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveValue(
                  mobile: 16.0,
                  tablet: 24.0,
                  desktop: 32.0,
                ),
                vertical: context.responsiveValue(
                  mobile: 16.0,
                  tablet: 24.0,
                  desktop: 32.0,
                ),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - kToolbarHeight - MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16.0,
                  ),
                  child: IntrinsicHeight(
        child: Form(
          key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                        Text(
                  'Karatapp',
                  style: TextStyle(
                            fontSize: context.responsiveValue(
                              mobile: 28.0,
                              tablet: 32.0,
                              desktop: 36.0,
                            ),
                    fontWeight: FontWeight.bold,
                  ),
                          textAlign: TextAlign.center,
                ),
                        SizedBox(height: context.responsiveValue(
                          mobile: 32.0,
                          tablet: 40.0,
                          desktop: 48.0,
                        )),
                if (_errorMessage != null)
                  Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                                width: 1,
                              ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                    ),
                  ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                  ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Voer je e-mailadres in';
                    }
                    if (!(_emailRegex as RegExp).hasMatch(value)) { // ignore: deprecated_member_use
                      return 'Voer een geldig e-mailadres in';
                    }
                    return null;
                  },
                ),
                        SizedBox(height: context.responsiveValue(
                          mobile: 12.0,
                          tablet: 16.0,
                          desktop: 20.0,
                        )),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Wachtwoord',
                    border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
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
                        SizedBox(height: context.responsiveValue(
                          mobile: 20.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        )),
                        SizedBox(height: context.responsiveValue(
                          mobile: 20.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        )),
                        // Register button on first line
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => context.goToSignup(),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Registreren',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: context.responsiveValue(
                          mobile: 16.0,
                          tablet: 20.0,
                          desktop: 24.0,
                        )),
                        // Login button on second line
                SizedBox(
                  width: double.infinity,
                          height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                    child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Inloggen',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                    ),
                                  ),
                          ),
                        ),
                        // Add bottom padding to ensure content doesn't get cut off
                        SizedBox(height: context.responsiveValue(
                          mobile: 20.0,
                          tablet: 24.0,
                          desktop: 28.0,
                        )),
                  ],
                ),
                  ),
            ),
          ),
              ),
            );
          },
        ),
      ),
    );
  }
}
