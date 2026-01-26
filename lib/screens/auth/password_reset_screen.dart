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
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSavingPassword = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
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
          content: Text('Open de reset-link om het wachtwoord te wijzigen.'),
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
          leading: BackButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.goToLogin();
              }
            },
          ),
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
                    'Stel hieronder je nieuwe wachtwoord in.',
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
