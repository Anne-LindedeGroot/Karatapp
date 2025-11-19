// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../core/navigation/scaffold_messenger.dart';
import '../core/navigation/app_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static final _emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Karatapp',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Voer je e-mailadres in';
                    }
                    if (!_emailRegex.hasMatch(value)) {
                      return 'Voer een geldig e-mailadres in';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Wachtwoord',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
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
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Inloggen'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nog geen account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.goToSignup(),
                      child: const Text('Registreren'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
