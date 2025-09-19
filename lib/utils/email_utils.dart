import 'package:email_validator/email_validator.dart';

class EmailUtils {
  /// Parse a string containing multiple email addresses
  /// Supports comma, semicolon, space, and newline separated emails
  static List<String> parseEmailString(String emailString) {
    if (emailString.trim().isEmpty) return [];

    // Split by common separators
    List<String> emails = emailString
        .split(RegExp(r'[,;\s\n\r]+'))
        .map((email) => email.trim())
        .where((email) => email.isNotEmpty)
        .toList();

    // Remove duplicates while preserving order
    Set<String> seen = {};
    return emails.where((email) => seen.add(email.toLowerCase())).toList();
  }

  /// Validate a list of email addresses
  static Map<String, List<String>> validateEmails(List<String> emails) {
    List<String> valid = [];
    List<String> invalid = [];

    for (String email in emails) {
      if (EmailValidator.validate(email)) {
        valid.add(email);
      } else {
        invalid.add(email);
      }
    }

    return {
      'valid': valid,
      'invalid': invalid,
    };
  }

  /// Check if a single email address is valid
  static bool isValidEmail(String email) {
    return EmailValidator.validate(email.trim());
  }

  /// Format email list for display
  static String formatEmailList(List<String> emails, {int maxDisplay = 5}) {
    if (emails.isEmpty) return 'No recipients';
    
    if (emails.length <= maxDisplay) {
      return emails.join(', ');
    } else {
      List<String> displayed = emails.take(maxDisplay).toList();
      int remaining = emails.length - maxDisplay;
      return '${displayed.join(', ')} and $remaining more...';
    }
  }

  /// Get common email domains for suggestions
  static List<String> getCommonEmailDomains() {
    return [
      'gmail.com',
      'yahoo.com',
      'outlook.com',
      'hotmail.com',
      'icloud.com',
      'aol.com',
      'live.com',
      'msn.com',
    ];
  }

  /// Suggest corrections for common typos in email domains
  static String suggestEmailCorrection(String email) {
    if (!email.contains('@')) return email;

    List<String> parts = email.split('@');
    if (parts.length != 2) return email;

    String localPart = parts[0];
    String domain = parts[1].toLowerCase();

    // Common typo corrections
    Map<String, String> domainCorrections = {
      'gmai.com': 'gmail.com',
      'gmial.com': 'gmail.com',
      'gmail.co': 'gmail.com',
      'yahooo.com': 'yahoo.com',
      'yaho.com': 'yahoo.com',
      'outlok.com': 'outlook.com',
      'hotmial.com': 'hotmail.com',
      'hotmil.com': 'hotmail.com',
    };

    String correctedDomain = domainCorrections[domain] ?? domain;
    return '$localPart@$correctedDomain';
  }

  /// Extract emails from text using regex
  static List<String> extractEmailsFromText(String text) {
    final emailRegex = RegExp(
      r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'
    );
    
    return emailRegex
        .allMatches(text)
        .map((match) => match.group(0)!)
        .toSet()
        .toList();
  }
}