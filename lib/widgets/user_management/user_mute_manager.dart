import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/mute_service.dart';
import '../../providers/mute_provider.dart';
import '../../widgets/enhanced_accessible_text.dart';
import '../../widgets/tts_clickable_text.dart';
import '../../widgets/global_tts_overlay.dart';

class UserMuteManager extends ConsumerWidget {
  final String userId;
  final String userName;

  const UserMuteManager({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muteAsync = ref.watch(currentMuteProvider(userId));
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return muteAsync.when(
      data: (muteInfo) {
        final isMuted = muteInfo != null && !muteInfo.isExpired;
        final muteIconColor = isMuted
            ? Colors.red
            : (isDarkMode ? Colors.grey[400] : Colors.grey[600]);

        return PopupMenuButton<String>(
          icon: Icon(
            isMuted ? Icons.volume_off : Icons.volume_up,
            color: muteIconColor,
            size: 20,
          ),
          tooltip: isMuted ? 'Gebruiker is gedempt' : 'Gebruiker dempen',
          itemBuilder: (context) {
            if (isMuted) {
              return [
                PopupMenuItem<String>(
                  value: 'unmute',
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Row(
                      children: [
                        const Icon(Icons.volume_up, color: Colors.green),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Gebruiker Ontdempen'),
                              Text(
                                'Gedempt tot: ${muteInfo.mutedUntil.day}/${muteInfo.mutedUntil.month}/${muteInfo.mutedUntil.year}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.visible,
                              ),
                              Text(
                                'Tijd over: ${muteInfo.timeRemainingText}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.visible,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'view_history',
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const Row(
                      children: [
                        Icon(Icons.history, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dempgeschiedenis Bekijken',
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            } else {
              return [
                PopupMenuItem<String>(
                  value: 'mute_1day',
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const Row(
                      children: [
                        Icon(Icons.volume_off, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dempen voor 1 Dag',
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'mute_3days',
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const Row(
                      children: [
                        Icon(Icons.volume_off, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dempen voor 3 Dagen',
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'mute_1week',
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const Row(
                      children: [
                        Icon(Icons.volume_off, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dempen voor 1 Week',
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'mute_1month',
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const Row(
                      children: [
                        Icon(Icons.volume_off, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dempen voor 1 Maand',
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'mute_3months',
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const Row(
                      children: [
                        Icon(Icons.volume_off, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dempen voor 3 Maanden',
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'mute_6months',
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const Row(
                      children: [
                        Icon(Icons.volume_off, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dempen voor 6 Maanden',
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'mute_1year',
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const Row(
                      children: [
                        Icon(Icons.volume_off, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dempen voor 1 Jaar',
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'mute_custom',
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.purple),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Aangepaste Duur',
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'view_history',
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: const Row(
                      children: [
                        Icon(Icons.history, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Dempgeschiedenis Bekijken',
                            overflow: TextOverflow.visible,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            }
          },
          onSelected: (String action) {
            _handleMuteAction(context, ref, action);
          },
        );
      },
      loading: () =>
          const Icon(Icons.hourglass_empty, size: 20, color: Colors.grey),
      error: (error, stackTrace) =>
          const Icon(Icons.error, size: 20, color: Colors.red),
    );
  }

  void _handleMuteAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'unmute':
        _unmuteUser(context, ref);
        break;
      case 'mute_1day':
        _muteUser(context, ref, MuteDuration.oneDay);
        break;
      case 'mute_3days':
        _muteUser(context, ref, MuteDuration.threeDays);
        break;
      case 'mute_1week':
        _muteUser(context, ref, MuteDuration.oneWeek);
        break;
      case 'mute_1month':
        _muteUser(context, ref, MuteDuration.oneMonth);
        break;
      case 'mute_3months':
        _muteUser(context, ref, MuteDuration.threeMonths);
        break;
      case 'mute_6months':
        _muteUser(context, ref, MuteDuration.sixMonths);
        break;
      case 'mute_1year':
        _muteUser(context, ref, MuteDuration.oneYear);
        break;
      case 'mute_custom':
        _showCustomMuteDialog(context, ref);
        break;
      case 'view_history':
        _showMuteHistory(context, ref);
        break;
    }
  }

  Future<void> _muteUser(BuildContext context, WidgetRef ref, MuteDuration duration) async {
    final reason = await _showReasonDialog(context, '$userName Dempen',
        'Geef een reden op voor het dempen van deze gebruiker:');
    if (reason == null || reason.trim().isEmpty) return;

    try {
      final muteNotifier = ref.read(muteNotifierProvider.notifier);
      final success = await muteNotifier.muteUser(
        userId: userId,
        duration: duration,
        reason: reason.trim(),
      );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$userName succesvol gedempt voor ${duration.displayName}',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kon $userName niet dempen'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij dempen gebruiker: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _unmuteUser(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          title: Text('$userName Ontdempen'),
          content: Text('Weet je zeker dat je $userName wilt ontdempen?'),
          actions: [
            TTSClickableWidget(
              ttsText: 'Annuleren knop',
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuleren'),
              ),
            ),
            TTSClickableWidget(
              ttsText: 'Ontdempen knop',
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ontdempen'),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final muteNotifier = ref.read(muteNotifierProvider.notifier);
        final success = await muteNotifier.unmuteUser(userId);

        if (context.mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$userName succesvol ontdempt'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kon $userName niet ontdempen'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fout bij ontdempen gebruiker: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<String?> _showReasonDialog(BuildContext context, String title, String prompt) async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(prompt),
              const SizedBox(height: 16),
              EnhancedAccessibleTextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Voer reden in...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
                customTTSLabel: 'Reden invoerveld',
              ),
            ],
          ),
          actions: [
            TTSClickableWidget(
              ttsText: 'Annuleren knop',
              child: TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Annuleren'),
              ),
            ),
            TTSClickableWidget(
              ttsText: 'Bevestigen knop',
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Bevestigen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomMuteDialog(BuildContext context, WidgetRef ref) async {
    MuteDuration? selectedDuration;

    final duration = await showDialog<MuteDuration>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Aangepaste Duur voor $userName'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400, // Fixed height to prevent overflow
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: MuteDuration.values.map((duration) {
                return ListTile(
                  title: Text(duration.displayName),
                  subtitle: Text(
                    duration.description,
                    style: const TextStyle(fontSize: 12),
                  ),
                  leading: Icon(
                    selectedDuration == duration
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selectedDuration == duration
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  onTap: () {
                    selectedDuration = duration;
                    Navigator.pop(context, duration);
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuleren'),
          ),
        ],
      ),
    );

    if (duration != null && context.mounted) {
      await _muteUser(context, ref, duration);
    }
  }

  Future<void> _showMuteHistory(BuildContext context, WidgetRef ref) async {
    final muteNotifier = ref.read(muteNotifierProvider.notifier);
    final history = await muteNotifier.getUserMuteHistory(userId);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dempgeschiedenis voor $userName'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: history.isEmpty
              ? const Center(child: Text('Geen dempgeschiedenis'))
              : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final mute = history[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          mute.isActive ? Icons.volume_off : Icons.volume_up,
                          color: mute.isActive ? Colors.red : Colors.green,
                        ),
                        title: Text(mute.reason),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gedempt: ${mute.mutedAt.day}/${mute.mutedAt.month}/${mute.mutedAt.year}',
                            ),
                            Text(
                              'Tot: ${mute.mutedUntil.day}/${mute.mutedUntil.month}/${mute.mutedUntil.year}',
                            ),
                            if (!mute.isActive && mute.unmutedAt != null)
                              Text(
                                'Ontdempt: ${mute.unmutedAt!.day}/${mute.unmutedAt!.month}/${mute.unmutedAt!.year}',
                              ),
                          ],
                        ),
                        trailing: mute.isActive
                            ? Text(
                                mute.timeRemainingText,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Icon(Icons.check, color: Colors.green),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }
}
