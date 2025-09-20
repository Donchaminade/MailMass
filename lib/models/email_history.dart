


import 'package:cursormailer/models/email_model.dart';


enum EmailSendStatus {
  success,
  failed,
  partial,
}

class EmailHistoryEntry {
  final EmailModel email;
  final DateTime timestamp;
  final EmailSendStatus status;
  final Map<String, String> results;

  EmailHistoryEntry({
    required this.email,
    required this.timestamp,
    required this.status,
    required this.results,
  });
}
