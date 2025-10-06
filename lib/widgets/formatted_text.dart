import 'package:flutter/material.dart';

class FormattedText extends StatelessWidget {
  final String text;
  final TextStyle? baseStyle;
  final TextStyle? headingStyle;

  const FormattedText({
    super.key,
    required this.text,
    this.baseStyle,
    this.headingStyle,
  });

  @override
  Widget build(BuildContext context) {
    // Split text by newlines to handle paragraphs
    final paragraphs = text.split('\n');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: paragraphs.map((paragraph) {
        return _buildFormattedParagraph(paragraph, context);
      }).toList(),
    );
  }

  Widget _buildFormattedParagraph(String paragraph, BuildContext context) {
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
            style: baseStyle ?? Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: '$beforeColon: ',
                style: headingStyle ?? Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextSpan(text: afterColon),
            ],
          ),
        );
      } else {
        // For other text with colons, just display normally
        return Text(paragraph, style: baseStyle ?? Theme.of(context).textTheme.bodyMedium);
      }
    } else {
      // No colon, display normally
      return Text(paragraph, style: baseStyle ?? Theme.of(context).textTheme.bodyMedium);
    }
  }
}
