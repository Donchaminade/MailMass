import 'package:flutter/material.dart';
import '../utils/email_utils.dart';

class EmailChip extends StatelessWidget {
  final String email;
  final VoidCallback onDeleted;
  final bool isValid;

  const EmailChip({
    Key? key,
    required this.email,
    required this.onDeleted,
    bool? isValid,
  }) : isValid = isValid ?? true, super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool emailValid = isValid && EmailUtils.isValidEmail(email);
    
    return Chip(
      label: Text(
        email,
        style: TextStyle(
          color: emailValid ? Colors.black87 : Colors.red[700],
          fontSize: 13,
        ),
      ),
      backgroundColor: emailValid 
          ? Colors.blue[50] 
          : Colors.red[50],
      deleteIcon: Icon(
        Icons.close,
        size: 18,
        color: emailValid ? Colors.blue[700] : Colors.red[700],
      ),
      onDeleted: onDeleted,
      side: BorderSide(
        color: emailValid 
            ? Colors.blue[200]! 
            : Colors.red[300]!,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class EmailChipList extends StatelessWidget {
  final List<String> emails;
  final Function(String) onEmailRemoved;
  final int maxDisplayRows;

  const EmailChipList({
    Key? key,
    required this.emails,
    required this.onEmailRemoved,
    this.maxDisplayRows = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (emails.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No email addresses added yet. Paste your email list above.',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxDisplayRows * 50.0, // Approximate height per row
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: emails.map((email) {
            return EmailChip(
              email: email,
              onDeleted: () => onEmailRemoved(email),
            );
          }).toList(),
        ),
      ),
    );
  }
}