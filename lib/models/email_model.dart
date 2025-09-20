import 'dart:io';

class EmailModel {
  final String subject;
  final String message;
  final List<String> recipients;
  final List<File> attachments;

  EmailModel({
    required this.subject,
    required this.message,
    required this.recipients,
    this.attachments = const [],
  });

  EmailModel copyWith({
    String? subject,
    String? message,
    List<String>? recipients,
    List<File>? attachments,
  }) {
    return EmailModel(
      subject: subject ?? this.subject,
      message: message ?? this.message,
      recipients: recipients ?? this.recipients,
      attachments: attachments ?? this.attachments,
    );
  }

  bool get isValid {
    return subject.isNotEmpty && 
           message.isNotEmpty && 
           recipients.isNotEmpty;
  }

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'message': message,
      'recipients': recipients,
      'attachments': attachments.map((file) => file.path).toList(),
    };
  }

  factory EmailModel.fromJson(Map<String, dynamic> json) {
    return EmailModel(
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      recipients: List<String>.from(json['recipients'] ?? []),
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((path) => File(path as String))
          .toList() ?? [],
    );
  }
}

