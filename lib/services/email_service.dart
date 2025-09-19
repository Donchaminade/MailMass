import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../models/email_model.dart';

class EmailService {
  String? _senderEmail;
  String? _senderPassword;
  static const String _senderName = 'MassMail App';

  Future<void> loadCredentials() async {
    await dotenv.load(fileName: ".env");
    _senderEmail = dotenv.env['GMAIL_EMAIL'];
    _senderPassword = dotenv.env['GMAIL_PASSWORD'];
  }

  Future<Map<String, String>> sendEmails(EmailModel emailData, {
    Function(int, int)? onProgress,
  }) async {
    await loadCredentials();
    if (_senderEmail == null || _senderPassword == null) {
      return {'error': 'Email credentials not loaded from .env file'};
    }

    final smtpServer = gmail(_senderEmail!, _senderPassword!);
    final Map<String, String> results = {};
    int successCount = 0;
    final totalCount = emailData.recipients.length;

    for (int i = 0; i < totalCount; i++) {
      final recipient = emailData.recipients[i];
      try {
        final message = Message()
          ..from = Address(_senderEmail!, _senderName)
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
        for (var p in e.problems) {
          print('Problem: ${p.code}: ${p.msg}');
        }
      } catch (e) {
        results[recipient] = 'Failed: $e';
      }
      onProgress?.call(i + 1, totalCount);
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

  Future<bool> testEmailConfiguration() async {
    await loadCredentials();
    if (_senderEmail == null || _senderPassword == null) {
      print('Error: Email credentials not loaded from .env file');
      return false;
    }

    try {
      final smtpServer = gmail(_senderEmail!, _senderPassword!);
      final message = Message()
        ..from = Address(_senderEmail!, _senderName)
        ..recipients.add(_senderEmail!)
        ..subject = 'MassMail Test Email'
        ..text = 'This is a test email from MassMail app.';

      await send(message, smtpServer);
      return true;
    } catch (e) {
      print('Email configuration test failed: $e');
      return false;
    }
  }
}