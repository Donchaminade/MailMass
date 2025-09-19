import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/email_model.dart';

Future<Map<String, String>> sendEmailsInIsolate(Map<String, dynamic> data) async {
  final emailData = data['emailData'] as EmailModel;
  final senderEmail = data['senderEmail'] as String;
  final senderPassword = data['senderPassword'] as String;

  final emailService = EmailService();
  return await emailService.sendEmails(emailData, senderEmail, senderPassword);
}

class EmailService {
  static const String _senderName = 'CursorMailer';

  Future<Map<String, String>> sendEmails(EmailModel emailData, String senderEmail, String senderPassword) async {
    final smtpServer = gmail(senderEmail, senderPassword);
    final Map<String, String> results = {};
    int successCount = 0;
    final totalCount = emailData.recipients.length;

    for (int i = 0; i < totalCount; i++) {
      final recipient = emailData.recipients[i];
      try {
        final message = Message()
          ..from = Address(senderEmail, _senderName)
          ..recipients.add(recipient)
          ..subject = emailData.subject
          ..html = _formatMessageAsHtml(emailData.message);

        for (var attachment in emailData.attachments) {
          if (await attachment.exists()) {
            message.attachments.add(FileAttachment(attachment));
          }
        }

        await send(message, smtpServer);
        results[recipient] = 'Success';
        successCount++;
      } on MailerException catch (e) {
        results[recipient] = 'Failed: ${e.message}';
      } catch (e) {
        results[recipient] = 'Failed: $e';
      }
    }

    if (successCount == totalCount) {
      results['summary'] = 'All emails sent successfully.';
    } else {
      results['summary'] = '$successCount out of $totalCount emails sent successfully.';
    }

    return results;
  }

  String _formatMessageAsHtml(String message) {
    return message
        .replaceAll('\r\n', '<br>')
        .replaceAll('\n', '<br>')
        .replaceAll('\r', '<br>');
  }
}