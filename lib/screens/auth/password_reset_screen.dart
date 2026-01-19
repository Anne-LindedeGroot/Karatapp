import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/accessibility_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/enhanced_accessible_text.dart';
import '../../widgets/global_tts_overlay.dart';
import '../../supabase_client.dart';
import '../../core/navigation/app_router.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const PasswordResetScreen({super.key, this.initialEmail});

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSendingLink = false;
  bool _isSavingPassword = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _speakIfEnabled(String text) async {
    try {
      final accessibilityState = ref.read(accessibilityNotifierProvider);
      if (!accessibilityState.isTextToSpeechEnabled) return;
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      if (accessibilityNotifier.isSpeaking()) {
        await accessibilityNotifier.stopSpeaking();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      await accessibilityNotifier.speak(text);
    } catch (e) {
      debugPrint('PasswordResetScreen TTS Error: $e');
    }
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vul een e-mailadres in')),
      );
      return;
    }

    setState(() {
      _isSendingLink = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).sendPasswordResetEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reset link verstuurd. Controleer je e-mail.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset mislukt: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingLink = false;
        });
      }
    }
  }

  Future<void> _saveNewPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wachtwoord moet minimaal 6 tekens zijn')),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wachtwoorden komen niet overeen')),
      );
      return;
    }

    final session = SupabaseClientManager().client.auth.currentSession;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Open de reset-link uit je e-mail om het wachtwoord te wijzigen.'),
        ),
      );
      return;
    }

    setState(() {
      _isSavingPassword = true;
    });

    try {
      await ref.read(authNotifierProvider.notifier).updatePassword(newPassword);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wachtwoord bijgewerkt. Je kunt nu inloggen.'),
            backgroundColor: Colors.green,
          ),
        );
        context.goToLogin();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opslaan mislukt: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalTTSOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Wachtwoord reset'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: context.responsivePadding,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  const EnhancedAccessibleText(
                    'Reset je wachtwoord',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const EnhancedAccessibleText(
                    'Stuur eerst een reset-link, open daarna de link om je nieuwe wachtwoord in te stellen in de app.',
                  ),
                  SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
                  EnhancedAccessibleTextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email, AutofillHints.username],
                    customTTSLabel: 'E-mail invoerveld voor wachtwoord reset',
                  ),
                  SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSendingLink
                          ? null
                          : () {
                              _speakIfEnabled('Reset link sturen');
                              _sendResetLink();
                            },
                      child: _isSendingLink
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Reset link sturen'),
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing(SpacingSize.lg)),
                  const EnhancedAccessibleText(
                    'Nieuw wachtwoord instellen',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  EnhancedAccessibleTextField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Nieuw wachtwoord',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      helperText: 'Minimaal 6 tekens',
                      suffixIcon: IconButton(
                        tooltip: _isNewPasswordVisible ? 'Verberg wachtwoord' : 'Toon wachtwoord',
                        icon: Icon(
                          _isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isNewPasswordVisible = !_isNewPasswordVisible;
                          });
                          _speakIfEnabled(
                            _isNewPasswordVisible ? 'Wachtwoord tonen' : 'Wachtwoord verbergen',
                          );
                        },
                      ),
                    ),
                    obscureText: !_isNewPasswordVisible,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    customTTSLabel: 'Nieuw wachtwoord invoerveld, minimaal 6 tekens',
                  ),
                  SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
                  EnhancedAccessibleTextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Bevestig nieuw wachtwoord',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _isConfirmPasswordVisible ? 'Verberg wachtwoord' : 'Toon wachtwoord',
                        icon: Icon(
                          _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                          });
                          _speakIfEnabled(
                            _isConfirmPasswordVisible ? 'Wachtwoord tonen' : 'Wachtwoord verbergen',
                          );
                        },
                      ),
                    ),
                    obscureText: !_isConfirmPasswordVisible,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    customTTSLabel: 'Bevestig nieuw wachtwoord invoerveld',
                  ),
                  SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSavingPassword
                          ? null
                          : () {
                              _speakIfEnabled('Wachtwoord opslaan');
                              _saveNewPassword();
                            },
                      child: _isSavingPassword
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Wachtwoord opslaan'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
