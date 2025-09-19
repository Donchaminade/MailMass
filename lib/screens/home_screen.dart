import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/email_model.dart';
import '../services/email_service.dart';
import '../utils/email_utils.dart';
import '../widgets/email_chip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  
  final EmailService _emailService = EmailService();
  
  List<String> _recipients = [];
  List<File> _attachments = [];
  bool _isSending = false;
  int _sentCount = 0;
  int _totalCount = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onEmailTextChanged() {
    final text = _emailController.text;
    if (text.isNotEmpty && (text.endsWith(' ') || text.endsWith('\n'))) {
      _parseAndAddEmails();
    }
  }

  void _parseAndAddEmails() {
    final emailText = _emailController.text;
    if (emailText.trim().isEmpty) return;

    final newEmails = EmailUtils.parseEmailString(emailText);
    final validationResult = EmailUtils.validateEmails(newEmails);
    
    setState(() {
      // Add valid emails to recipients list, avoiding duplicates
      for (String email in validationResult['valid']!) {
        if (!_recipients.contains(email.toLowerCase())) {
          _recipients.add(email);
        }
      }
      
      // Clear the text field
      _emailController.clear();
    });

    // Show message if there were invalid emails
    if (validationResult['invalid']!.isNotEmpty) {
      _showInvalidEmailsDialog(validationResult['invalid']!);
    }
  }

  void _showInvalidEmailsDialog(List<String> invalidEmails) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Invalid Email Addresses'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('The following email addresses are invalid:'),
              const SizedBox(height: 8),
              ...invalidEmails.map((email) => Text('• $email')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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
            result.paths.map((path) => File(path!)).where((file) => file.existsSync())
          );
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
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
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

    final emailData = EmailModel(
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
      recipients: _recipients,
      attachments: _attachments,
    );

    setState(() {
      _isSending = true;
      _sentCount = 0;
      _totalCount = _recipients.length;
    });

    try {
      final results = await _emailService.sendEmails(
        emailData,
        onProgress: (sent, total) {
          setState(() {
            _sentCount = sent;
          });
        },
      );

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
      _showErrorDialog('Error sending emails: $e');
    }
  }

  void _showResultsDialog(Map<String, String> results) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Email Sending Results'),
          content: SingleChildScrollView(
            child: ListBody(
              children: results.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text('${entry.key}: ${entry.value}'),
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
              child: const Text('OK'),
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
          title: const Text('Success'),
          content: Text('Successfully sent emails to ${_recipients.length} recipients!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearAll();
              },
              child: const Text('OK'),
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
      appBar: AppBar(
        title: const Text('MassMail'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAll,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: _isSending ? _buildProgressView() : _buildMainView(),
    );
  }

  Widget _buildProgressView() {
    double progress = _totalCount > 0 ? _sentCount / _totalCount : 0;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.email,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          Text(
            'Sending emails...',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text('$_sentCount of $_totalCount sent'),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
          ),
          const SizedBox(height: 24),
          const Text(
            'Please don\'t close the app while sending...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email Recipients Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Recipients (${_recipients.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Paste email addresses here (comma, space, or line separated)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    maxLines: 3,
                    onChanged: (_) => _onEmailTextChanged(),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _parseAndAddEmails,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Emails'),
                  ),
                  const SizedBox(height: 16),
                  EmailChipList(
                    emails: _recipients,
                    onEmailRemoved: _removeEmail,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Email Content Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.message, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Email Content',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.subject),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.message),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 6,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Attachments Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.attach_file, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Attachments (${_attachments.length})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Files'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_attachments.isNotEmpty)
                    ...(_attachments.map((file) => Card(
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
                    )))
                  else
                    const Text(
                      'No attachments added. You can add files by clicking the "Add Files" button.',
                      style: TextStyle(color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Send Button
          ElevatedButton(
            onPressed: _recipients.isNotEmpty && 
                     _subjectController.text.isNotEmpty && 
                     _messageController.text.isNotEmpty
                ? _sendEmails
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send),
                const SizedBox(width: 8),
                Text(_recipients.isEmpty 
                    ? 'Add Recipients to Send'
                    : 'Send to ${_recipients.length} Recipients'),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}