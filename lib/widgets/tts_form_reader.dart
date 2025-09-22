import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';

/// TTS Form Reader Widget that can speak entire forms and their content
class TTSFormReader extends ConsumerWidget {
  final Widget child;
  final String formTitle;
  final List<TTSFormField> formFields;
  final String? submitButtonText;
  final String? cancelButtonText;
  final VoidCallback? onFormRead;

  const TTSFormReader({
    super.key,
    required this.child,
    required this.formTitle,
    required this.formFields,
    this.submitButtonText,
    this.cancelButtonText,
    this.onFormRead,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    
    if (!accessibilityState.isTextToSpeechEnabled) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton.small(
            onPressed: () => _readEntireForm(ref),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            tooltip: 'Formulier voorlezen',
            heroTag: 'form_reader_${formTitle.hashCode}',
            child: const Icon(Icons.record_voice_over, size: 20),
          ),
        ),
      ],
    );
  }

  void _readEntireForm(WidgetRef ref) async {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Build comprehensive form description
    String formDescription = _buildFormDescription();
    
    await accessibilityNotifier.speak(formDescription);
    onFormRead?.call();
  }

  String _buildFormDescription() {
    StringBuffer description = StringBuffer();
    
    // Form title
    description.write('Formulier: $formTitle. ');
    
    // Form fields count
    description.write('Dit formulier heeft ${formFields.length} velden. ');
    
    // Read each field
    for (int i = 0; i < formFields.length; i++) {
      final field = formFields[i];
      description.write('Veld ${i + 1}: ');
      description.write(field.getDescription());
      description.write(' ');
    }
    
    // Action buttons
    if (submitButtonText != null || cancelButtonText != null) {
      description.write('Beschikbare acties: ');
      if (submitButtonText != null) {
        description.write('$submitButtonText knop. ');
      }
      if (cancelButtonText != null) {
        description.write('$cancelButtonText knop. ');
      }
    }
    
    description.write('Gebruik de velden om je gegevens in te voeren.');
    
    return description.toString();
  }
}

/// Data class for form fields
class TTSFormField {
  final String label;
  final String? hint;
  final String? currentValue;
  final TTSFieldType type;
  final bool isRequired;
  final List<String>? options; // For dropdown/radio fields
  final String? validationMessage;

  const TTSFormField({
    required this.label,
    this.hint,
    this.currentValue,
    required this.type,
    this.isRequired = false,
    this.options,
    this.validationMessage,
  });

  String getDescription() {
    StringBuffer description = StringBuffer();
    
    // Field label
    description.write(label);
    
    // Required indicator
    if (isRequired) {
      description.write(' (verplicht)');
    }
    
    // Field type description
    switch (type) {
      case TTSFieldType.text:
        description.write(', tekstveld');
        break;
      case TTSFieldType.email:
        description.write(', email veld');
        break;
      case TTSFieldType.password:
        description.write(', wachtwoord veld');
        break;
      case TTSFieldType.number:
        description.write(', nummer veld');
        break;
      case TTSFieldType.multiline:
        description.write(', tekstveld met meerdere regels');
        break;
      case TTSFieldType.dropdown:
        description.write(', dropdown menu');
        if (options != null && options!.isNotEmpty) {
          description.write(' met opties: ${options!.join(', ')}');
        }
        break;
      case TTSFieldType.checkbox:
        description.write(', checkbox');
        break;
      case TTSFieldType.radio:
        description.write(', radio knoppen');
        if (options != null && options!.isNotEmpty) {
          description.write(' met opties: ${options!.join(', ')}');
        }
        break;
      case TTSFieldType.date:
        description.write(', datum veld');
        break;
      case TTSFieldType.time:
        description.write(', tijd veld');
        break;
    }
    
    // Current initialValue
    if (currentValue != null && currentValue!.isNotEmpty) {
      if (type == TTSFieldType.password) {
        description.write(', huidige waarde: wachtwoord ingevuld');
      } else {
        description.write(', huidige waarde: $currentValue');
      }
    } else {
      description.write(', nog niet ingevuld');
    }
    
    // Hint
    if (hint != null && hint!.isNotEmpty) {
      description.write(', hint: $hint');
    }
    
    // Validation message
    if (validationMessage != null && validationMessage!.isNotEmpty) {
      description.write(', foutmelding: $validationMessage');
    }
    
    description.write('.');
    
    return description.toString();
  }
}

/// Enum for different field types
enum TTSFieldType {
  text,
  email,
  password,
  number,
  multiline,
  dropdown,
  checkbox,
  radio,
  date,
  time,
}

/// TTS-enabled TextField wrapper
class TTSTextField extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final TTSFieldType fieldType;
  final bool isRequired;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final int? maxLines;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  const TTSTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.fieldType = TTSFieldType.text,
    this.isRequired = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.maxLines = 1,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
  });

  @override
  ConsumerState<TTSTextField> createState() => _TTSTextFieldState();
}

class _TTSTextFieldState extends ConsumerState<TTSTextField> {
  late FocusNode _focusNode;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _speakFieldInfo();
    }
  }

  void _speakFieldInfo() async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final field = TTSFormField(
      label: widget.label,
      hint: widget.hint,
      currentValue: widget.controller?.text,
      type: widget.fieldType,
      isRequired: widget.isRequired,
      validationMessage: _validationMessage,
    );
    
    await accessibilityNotifier.speak(field.getDescription());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.label + (widget.isRequired ? ' *' : ''),
            hintText: widget.hint,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ref.watch(accessibilityNotifierProvider).isTextToSpeechEnabled)
                  IconButton(
                    icon: const Icon(Icons.volume_up, size: 20),
                    onPressed: _speakFieldInfo,
                    tooltip: 'Veld informatie voorlezen',
                  ),
                if (widget.suffixIcon != null) widget.suffixIcon!,
              ],
            ),
            prefixIcon: widget.prefixIcon,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            final result = widget.validator?.call(value);
            setState(() {
              _validationMessage = result;
            });
            return result;
          },
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
        ),
        if (_validationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _validationMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

/// TTS-enabled DropdownButtonFormField wrapper
class TTSDropdownField<T> extends ConsumerStatefulWidget {
  final T? value;
  final String label;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final bool isRequired;

  const TTSDropdownField({
    super.key,
    this.value,
    required this.label,
    this.hint,
    required this.items,
    this.onChanged,
    this.validator,
    this.isRequired = false,
  });

  @override
  ConsumerState<TTSDropdownField<T>> createState() => _TTSDropdownFieldState<T>();
}

class _TTSDropdownFieldState<T> extends ConsumerState<TTSDropdownField<T>> {
  late FocusNode _focusNode;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _speakFieldInfo();
    }
  }

  void _speakFieldInfo() async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final options = widget.items
        .map((item) => item.child.toString())
        .toList();
    
    final field = TTSFormField(
      label: widget.label,
      hint: widget.hint,
      currentValue: widget.value?.toString(),
      type: TTSFieldType.dropdown,
      isRequired: widget.isRequired,
      options: options,
      validationMessage: _validationMessage,
    );
    
    await accessibilityNotifier.speak(field.getDescription());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<T>(
          initialValue: widget.value,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.label + (widget.isRequired ? ' *' : ''),
            hintText: widget.hint,
            suffixIcon: ref.watch(accessibilityNotifierProvider).isTextToSpeechEnabled
                ? IconButton(
                    icon: const Icon(Icons.volume_up, size: 20),
                    onPressed: _speakFieldInfo,
                    tooltip: 'Veld informatie voorlezen',
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
          items: widget.items,
          onChanged: widget.onChanged,
          validator: (value) {
            final result = widget.validator?.call(value);
            setState(() {
              _validationMessage = result;
            });
            return result;
          },
        ),
        if (_validationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _validationMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

/// TTS-enabled Checkbox wrapper
class TTSCheckboxField extends ConsumerWidget {
  final bool value;
  final String label;
  final void Function(bool?)? onChanged;
  final bool isRequired;

  const TTSCheckboxField({
    super.key,
    required this.value,
    required this.label,
    this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _speakFieldInfo(ref),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
          ),
          Expanded(
            child: Text(
              label + (isRequired ? ' *' : ''),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (ref.watch(accessibilityNotifierProvider).isTextToSpeechEnabled)
            IconButton(
              icon: const Icon(Icons.volume_up, size: 20),
              onPressed: () => _speakFieldInfo(ref),
              tooltip: 'Checkbox informatie voorlezen',
            ),
        ],
      ),
    );
  }

  void _speakFieldInfo(WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final field = TTSFormField(
      label: label,
      currentValue: value ? 'aangevinkt' : 'niet aangevinkt',
      type: TTSFieldType.checkbox,
      isRequired: isRequired,
    );
    
    await accessibilityNotifier.speak(field.getDescription());
  }
}

/// TTS-enabled Button wrapper
class TTSButton extends ConsumerWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final String? description;
  final ButtonStyle? style;

  const TTSButton({
    super.key,
    required this.child,
    this.onPressed,
    this.description,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: onPressed == null ? null : () {
        _speakButtonInfo(ref);
        onPressed!();
      },
      style: style,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          if (ref.watch(accessibilityNotifierProvider).isTextToSpeechEnabled) ...[
            const SizedBox(width: 8),
            const Icon(Icons.volume_up, size: 16),
          ],
        ],
      ),
    );
  }

  void _speakButtonInfo(WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    String buttonText = '';
    if (child is Text) {
      buttonText = (child as Text).data ?? '';
    } else if (description != null) {
      buttonText = description!;
    } else {
      buttonText = 'Knop';
    }
    
    await accessibilityNotifier.speak('$buttonText knop ingedrukt');
  }
}
