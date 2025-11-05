import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../utils/dialog_tts_helper.dart';
import '../widgets/global_tts_overlay.dart';
import '../widgets/tts_clickable_text.dart';

/// Test screen to demonstrate TTS functionality in popups and dialogs
class TTSTestScreen extends ConsumerStatefulWidget {
  const TTSTestScreen({super.key});

  @override
  ConsumerState<TTSTestScreen> createState() => _TTSTestScreenState();
}

class _TTSTestScreenState extends ConsumerState<TTSTestScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const TTSClickableText('TTS Popup Test'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TTSClickableText(
              'Test de TTS functionaliteit in popups en dialogen. Klik op de knoppen hieronder om verschillende dialogen te openen.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            
            // Test 1: Simple Alert Dialog
            ElevatedButton(
              onPressed: () => _showSimpleAlert(context),
              child: const Text('Eenvoudige Waarschuwing'),
            ),
            const SizedBox(height: 10),
            
            // Test 2: Confirmation Dialog
            ElevatedButton(
              onPressed: () => _showConfirmationDialog(context),
              child: const Text('Bevestigingsdialoog'),
            ),
            const SizedBox(height: 10),
            
            // Test 3: Error Dialog
            ElevatedButton(
              onPressed: () => _showErrorDialog(context),
              child: const Text('Foutmelding'),
            ),
            const SizedBox(height: 10),
            
            // Test 4: Success Dialog
            ElevatedButton(
              onPressed: () => _showSuccessDialog(context),
              child: const Text('Succesmelding'),
            ),
            const SizedBox(height: 10),
            
            // Test 5: Loading Dialog
            ElevatedButton(
              onPressed: () => _showLoadingDialog(context),
              child: const Text('Laaddialoog'),
            ),
            const SizedBox(height: 10),
            
            // Test 6: Custom Dialog with TTS Overlay
            ElevatedButton(
              onPressed: () => _showCustomDialog(context),
              child: const Text('Aangepaste Dialoog'),
            ),
            const SizedBox(height: 20),
            
            const TTSClickableText(
              'Tip: Klik op de TTS knop in de rechterbovenhoek van elke dialoog, of klik direct op de tekst om deze voor te laten lezen.',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSimpleAlert(BuildContext context) {
    DialogTTSHelper.showAlertDialog(
      context: context,
      title: 'Eenvoudige Waarschuwing',
      content: 'Dit is een test van de TTS functionaliteit in een eenvoudige waarschuwingsdialoog. De tekst zou voorgelezen moeten worden wanneer je op de TTS knop klikt of op de tekst zelf.',
      confirmText: 'OK',
    );
  }

  void _showConfirmationDialog(BuildContext context) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    DialogTTSHelper.showConfirmationDialog(
      context: context,
      title: 'Bevestiging Vereist',
      content: 'Weet je zeker dat je deze actie wilt uitvoeren? Deze dialoog test de TTS functionaliteit in bevestigingsdialogen.',
      confirmText: 'Ja, Doorgaan',
      cancelText: 'Nee, Annuleren',
      confirmButtonColor: Colors.green,
    ).then((confirmed) {
      if (confirmed && mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Actie bevestigd!')),
        );
      }
    });
  }

  void _showErrorDialog(BuildContext context) {
    DialogTTSHelper.showErrorDialog(
      context: context,
      title: 'Er is een Fout Opgetreden',
      message: 'Dit is een test van de TTS functionaliteit in een foutmelding. De foutmelding zou voorgelezen moeten worden.',
    );
  }

  void _showSuccessDialog(BuildContext context) {
    DialogTTSHelper.showSuccessDialog(
      context: context,
      title: 'Actie Succesvol Voltooid',
      message: 'Gefeliciteerd! De actie is succesvol voltooid. Dit is een test van de TTS functionaliteit in een succesmelding.',
    );
  }

  void _showLoadingDialog(BuildContext context) {
    final navigator = Navigator.of(context);
    DialogTTSHelper.showLoadingDialog(
      context: context,
      message: 'Bezig met laden van gegevens...',
    );
    
    // Close the loading dialog after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        navigator.pop();
        // Use a different approach to avoid BuildContext async gap
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            DialogTTSHelper.showSuccessDialog(
              context: context,
              message: 'Laden voltooid!',
            );
          }
        });
      }
    });
  }

  void _showCustomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          title: const TTSClickableText('Aangepaste Dialoog'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TTSClickableText(
                'Dit is een aangepaste dialoog met meerdere tekstblokken. Elk tekstblok kan individueel worden voorgelezen door erop te klikken.',
              ),
              const SizedBox(height: 16),
              const TTSClickableText(
                'Deze tweede paragraaf test of meerdere tekstblokken correct werken met de TTS functionaliteit.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const TTSClickableText(
                  'Dit is een tekstblok in een gekleurde container. Ook deze tekst kan worden voorgelezen.',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          actions: [
            TTSClickableWidget(
              ttsText: 'Sluiten knop',
              child: TextButton(
                onPressed: () {
                  if (GoRouter.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: const Text('Sluiten'),
              ),
            ),
            TTSClickableWidget(
              ttsText: 'Meer Info knop',
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showMoreInfoDialog(context);
                },
                child: const Text('Meer Info'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreInfoDialog(BuildContext context) {
    DialogTTSHelper.showAlertDialog(
      context: context,
      title: 'Meer Informatie',
      content: 'Dit is een vervolgdialoog die wordt getoond na het klikken op de "Meer Info" knop. De TTS functionaliteit werkt ook in deze dialoog.',
      confirmText: 'Begrepen',
    );
  }
}
