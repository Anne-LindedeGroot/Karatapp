import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/accessibility_provider.dart';
import '../providers/role_provider.dart';
import '../services/role_service.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/accessible_text.dart';
import '../widgets/context_aware_page_tts_button.dart';
import '../core/navigation/app_router.dart';
import 'avatar_selection_screen.dart';

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
          ContextAwarePageTTSButton(
            context: PageTTSContext.profile,
            iconSize: 24.0,
            tooltip: 'Profiel voorlezen',
          ),
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
          padding: const EdgeInsets.all(16.0),
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
                const AccessibleText(
                  'Gebruikersprofiel',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  enableTextToSpeech: true,
                ),
                const SizedBox(height: 30),
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
                    size: 120,
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
                const SizedBox(height: 30),
                if (errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
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
                      borderRadius: BorderRadius.circular(8),
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
                const SizedBox(height: 20),
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
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: roleColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(roleIcon, color: roleColor, size: 18),
                              const SizedBox(width: 8),
                              AccessibleText(
                                role.displayName,
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                enableTextToSpeech: true,
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
                          borderRadius: BorderRadius.circular(20),
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
                          borderRadius: BorderRadius.circular(20),
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 20),
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
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 56, // Match TextField height
                      child: IconButton(
                        icon: const Icon(Icons.headphones),
                        tooltip: 'Naam veld voorlezen',
                        onPressed: () async {
                          final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
                          final currentValue = _nameController.text.trim();
                          final content = currentValue.isNotEmpty 
                              ? 'Volledige naam veld. Huidige waarde: $currentValue'
                              : 'Volledige naam veld. Veld is leeg. Voer uw volledige naam in.';
                          await accessibilityNotifier.speak(content);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
