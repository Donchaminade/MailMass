import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart'; // Import for compute
// Removed import 'package:flutter_dotenv/flutter_dotenv.dart'; // Removed as dotenv.load is moved to main.dart
import 'package:lottie/lottie.dart'; // Import for Lottie animations
import '../models/email_model.dart';
import '../services/email_service.dart'; // This will be used for the top-level function
import '../utils/email_utils.dart';
import '../widgets/email_chip.dart';
import '../widgets/fade_in.dart';

class HomeScreen extends StatefulWidget {
  final String? senderEmail;
  final String? senderPassword;

  const HomeScreen({
    Key? key,
    this.senderEmail,
    this.senderPassword,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<String> _recipients = [];
  List<File> _attachments = [];
  bool _isSending = false;
  // Removed _sentCount and _totalCount as they are not updated in real-time anymore

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _parseAndAddEmails() {
    final emailText = _emailController.text;
    if (emailText.trim().isEmpty) return;

    final newEmails = EmailUtils.parseEmailString(emailText);
    final validationResult = EmailUtils.validateEmails(newEmails);

    setState(() {
      for (String email in validationResult['valid']!) {
        if (!_recipients.contains(email.toLowerCase())) {
          _recipients.add(email);
        }
      }
      _emailController.clear();
    });

    if (validationResult['invalid']!.isNotEmpty) {
      _showInvalidEmailsDialog(validationResult['invalid']!);
    }
  }

  void _showInvalidEmailsDialog(List<String> invalidEmails) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Invalid Email Addresses', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The following email addresses are invalid:', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 8),
              ...invalidEmails.map((email) => Text('• $email', style: const TextStyle(color: Colors.white))),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _removeEmail(String email) {
    setState(() {
      _recipients.remove(email);
    });
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any,
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(
              result.paths.map((path) => File(path!)).where((file) => file.existsSync()));
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking files: $e');
    }
  }

  void _removeAttachment(File file) {
    setState(() {
      _attachments.remove(file);
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Error', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/error_icon.json', repeat: false, width: 100, height: 100),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendEmails() async {
    if (_recipients.isEmpty) {
      _showErrorDialog('Please add at least one recipient email address.');
      return;
    }

    if (_subjectController.text.trim().isEmpty) {
      _showErrorDialog('Please enter an email subject.');
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      _showErrorDialog('Please enter an email message.');
      return;
    }

    setState(() {
      _isSending = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    // Use credentials passed from main.dart
    final senderEmail = widget.senderEmail;
    final senderPassword = widget.senderPassword;

    if (senderEmail == null || senderPassword == null) {
      setState(() {
        _isSending = false;
      });
      _showErrorDialog('Email credentials not available. Please restart the app and ensure your .env file is correctly configured.');
      return;
    }

    final emailData = EmailModel(
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
      recipients: _recipients,
      attachments: _attachments,
    );

    try {
      final results = await compute(sendEmailsInIsolate, {
        'emailData': emailData,
        'senderEmail': senderEmail,
        'senderPassword': senderPassword,
      });

      setState(() {
        _isSending = false;
      });

      if (results.containsKey('error')) {
        _showErrorDialog(results['error']!);
      } else if (results['summary'] != 'All emails sent successfully.') {
        _showResultsDialog(results);
      } else {
        _showSuccessDialog();
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      print(e);
      _showErrorDialog('An unexpected error occurred while sending emails. Please check your credentials and internet connection.\n\nError: $e');
    }
  }

  void _showResultsDialog(Map<String, String> results) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Email Sending Results', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: ListBody(
              children: results.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${entry.key}: ${entry.value}', style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAll();
              },
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Success', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset('assets/success_icon.json', repeat: false, width: 100, height: 100),
              const SizedBox(height: 16),
              Text('Successfully sent emails to ${_recipients.length} recipients!', style: const TextStyle(color: Colors.white)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAll();
              },
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _clearAll() {
    setState(() {
      _recipients.clear();
      _attachments.clear();
      _subjectController.clear();
      _messageController.clear();
      _emailController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isSending ? _buildProgressView() : _buildMainView(),
      floatingActionButton: _isSending
          ? null
          : OpenContainer(
              transitionType: ContainerTransitionType.fade,
              openBuilder: (BuildContext context, VoidCallback _) {
                return const Scaffold();
              },
              closedElevation: 6.0,
              closedShape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(56 / 2),
                ),
              ),
              closedColor: Theme.of(context).primaryColor,
              closedBuilder: (BuildContext context, VoidCallback openContainer) {
                return FloatingActionButton.extended(
                  onPressed: _sendEmails,
                  label: const Text('Send', style: TextStyle(color: Colors.black)),
                  icon: Lottie.asset('assets/send_icon.json', repeat: true, width: 24, height: 24),
                );
              },
            ),
    );
  }

  Widget _buildProgressView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('assets/email_icon.json', repeat: true, width: 150, height: 150),
          const SizedBox(height: 24),
          Text(
            'Sending emails...', 
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 150.0,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text('CursorMailer'),
            background: Container(
              color: Colors.black,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAll,
              tooltip: 'Clear All',
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildRecipientsCard(),
                const SizedBox(height: 16),
                _buildContentCard(),
                const SizedBox(height: 16),
                _buildAttachmentsCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipientsCard() {
    return FadeIn(
      duration: const Duration(milliseconds: 500),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recipients (${_recipients.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Paste email addresses here',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _parseAndAddEmails,
                child: const Text('Valider'),
              ),
              const SizedBox(height: 24),
              EmailChipList(
                emails: _recipients,
                onEmailRemoved: _removeEmail,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard() {
    return FadeIn(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 200),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Content',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentsCard() {
    return FadeIn(
      duration: const Duration(milliseconds: 500),
      delay: const Duration(milliseconds: 400),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Attachments (${_attachments.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _pickFiles,
                child: const Text('Add Files'),
              ),
              const SizedBox(height: 24),
              if (_attachments.isNotEmpty)
                ..._attachments.map((file) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(file.path.split(Platform.pathSeparator).last),
                        subtitle: Text('${(file.lengthSync() / 1024).toStringAsFixed(1)} KB'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _removeAttachment(file),
                        ),
                      ),
                    ))
              else
                const Text(
                  'No attachments added.',
                  style: TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
