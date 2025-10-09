import 'package:flutter/material.dart';

class FormattedText extends StatefulWidget {
  final String text;
  final TextStyle? baseStyle;
  final TextStyle? headingStyle;
  final bool enableSelectiveCollapse;

  const FormattedText({
    super.key,
    required this.text,
    this.baseStyle,
    this.headingStyle,
    this.enableSelectiveCollapse = false,
  });

  @override
  State<FormattedText> createState() => _FormattedTextState();
}

class _FormattedTextState extends State<FormattedText> {
  bool _isKataUitlegExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enableSelectiveCollapse) {
      // Original behavior - show all text without truncation
      return _buildOriginalText(context);
    }
    
    // New selective collapse behavior
    return _buildSelectiveCollapsibleText(context);
  }

  Widget _buildOriginalText(BuildContext context) {
    // Split text by newlines to handle paragraphs
    final paragraphs = widget.text.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        return _buildFormattedParagraph(paragraph, context, false);
      }).toList(),
    );
  }

  Widget _buildSelectiveCollapsibleText(BuildContext context) {
    final paragraphs = widget.text.split('\n');
    final List<Widget> widgets = [];
    bool foundKataUitleg = false;
    final List<String> kataUitlegParagraphs = [];
    
    for (final paragraph in paragraphs) {
      if (paragraph.toLowerCase().contains('kata uitleg:')) {
        foundKataUitleg = true;
        kataUitlegParagraphs.add(paragraph);
      } else if (foundKataUitleg) {
        // Add subsequent paragraphs to kata uitleg section
        kataUitlegParagraphs.add(paragraph);
      } else {
        // Add to main content (always visible)
        widgets.add(_buildFormattedParagraph(paragraph, context, false));
      }
    }
    
    // Add kata uitleg section with collapse functionality
    if (foundKataUitleg) {
      widgets.add(_buildKataUitlegSection(kataUitlegParagraphs, context));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildKataUitlegSection(List<String> paragraphs, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle button - positioned above the heading
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _isKataUitlegExpanded = !_isKataUitlegExpanded;
                });
              },
              icon: Icon(
                _isKataUitlegExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18.0,
              ),
              label: Text(
                _isKataUitlegExpanded ? 'Minder zien' : 'Zie meer',
                style: const TextStyle(fontSize: 14.0),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ),
        
        // Show the entire kata uitleg section only when expanded
        if (_isKataUitlegExpanded) ...[
          // Show all paragraphs (heading + content)
          ...paragraphs.map((paragraph) => 
            _buildFormattedParagraph(paragraph, context, false)
          ),
        ],
      ],
    );
  }


  Widget _buildFormattedParagraph(String paragraph, BuildContext context, [bool isTruncated = false]) {
    // Check if paragraph contains a colon
    if (paragraph.contains(':')) {
      // Split only on the first colon to handle cases where there might be colons in the content
      final colonIndex = paragraph.indexOf(':');
      final beforeColon = paragraph.substring(0, colonIndex).trim();
      final afterColon = paragraph.substring(colonIndex + 1).trim();
      
      // Check if the text before colon is one of our target headings
      final isHeading = beforeColon.toLowerCase() == 'algemene informatie' || 
                       beforeColon.toLowerCase() == 'kata uitleg';
      
      if (isHeading) {
        // For our specific headings, make the heading bold
        return Text.rich(
          TextSpan(
            style: widget.baseStyle ?? Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: '$beforeColon: ',
                style: widget.headingStyle ?? Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: afterColon),
            ],
          ),
          // Show full text without truncation
        );
      } else {
        // For other text with colons, just display normally
        return Text(
          paragraph, 
          style: widget.baseStyle ?? Theme.of(context).textTheme.bodyMedium,
          // Show full text without truncation
        );
      }
    } else {
      // No colon, display normally
      return Text(
        paragraph, 
        style: widget.baseStyle ?? Theme.of(context).textTheme.bodyMedium,
        // Show full text without truncation
      );
    }
  }
}
