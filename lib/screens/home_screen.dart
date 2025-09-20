import 'dart:io';
import 'package:cursormailer/models/email_model.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:animations/animations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
// import 'package:mass_mail/models/email_model.dart';
import '../services/email_service.dart';
import '../utils/email_utils.dart';
import '../widgets/email_chip.dart';
import '../widgets/fade_in.dart';

import 'package:cursormailer/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  final String? senderEmail;
  final String? senderPassword;
  final Function(EmailModel, Map<String, String>)? onEmailsSent;
  final NotificationService notificationService;

  const HomeScreen({
    Key? key,
    this.senderEmail,
    this.senderPassword,
    this.onEmailsSent,
    required this.notificationService,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _subjectFocusNode = FocusNode();
  final FocusNode _messageFocusNode = FocusNode();

  List<String> _recipients = [];
  List<File> _attachments = [];
  bool _isSending = false;
  int _currentStep = 0;

  late AnimationController _fabAnimationController;
  late AnimationController _cardAnimationController;

  final kInputTextStyle = const TextStyle(color: Colors.black87);

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _emailFocusNode.dispose();
    _subjectFocusNode.dispose();
    _messageFocusNode.dispose();
    _fabAnimationController.dispose();
    _cardAnimationController.dispose();
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

    // Haptic feedback
    HapticFeedback.lightImpact();
  }

  void _showInvalidEmailsDialog(List<String> invalidEmails) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.shade800,
                  Colors.red.shade900,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Adresses e-mail invalides',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 206, 8, 8),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Les adresses suivantes sont invalides :',
                  style: TextStyle(color: const Color.fromARGB(179, 197, 13, 13), fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: BoxConstraints(maxHeight: 150),
                  child: SingleChildScrollView(
                    child: Column(
                      children: invalidEmails
                          .map((email) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(Icons.close, color: Colors.white70, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        email,
                                        style: TextStyle(color: Colors.black, fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('Compris', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeEmail(String email) {
    setState(() {
      _recipients.remove(email);
    });
    HapticFeedback.selectionClick();
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
        HapticFeedback.lightImpact();
        
        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text('${result.files.length} fichier(s) ajouté(s)'),
              ],
            ),
            backgroundColor: Colors.green.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de la sélection des fichiers : $e');
    }
  }

  void _removeAttachment(File file) {
    setState(() {
      _attachments.remove(file);
    });
    HapticFeedback.selectionClick();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.shade800,
                  Colors.red.shade900,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade800,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendEmails() async {
    // Validation avec feedback visuel amélioré
    if (_recipients.isEmpty) {
      _showValidationError('Veuillez ajouter au moins une adresse e-mail.', _emailFocusNode);
      return;
    }

    if (_subjectController.text.trim().isEmpty) {
      _showValidationError('Veuillez saisir un objet pour l\'e-mail.', _subjectFocusNode);
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      _showValidationError('Veuillez saisir un message.', _messageFocusNode);
      return;
    }

    setState(() {
      _isSending = true;
    });

    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(seconds: 2));

    final senderEmail = widget.senderEmail;
    final senderPassword = widget.senderPassword;

    if (senderEmail == null || senderPassword == null) {
      setState(() {
        _isSending = false;
      });
      _showErrorDialog('Informations d\'identification non disponibles. Veuillez redémarrer l\'application.');
      return;
    }

    final emailData = EmailModel(
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
      recipients: _recipients,
      attachments: _attachments,
    );

    try {
      final Map<String, String> results = await compute(sendEmailsInIsolate, {
        'emailData': emailData,
        'senderEmail': senderEmail,
        'senderPassword': senderPassword,
      });

      widget.onEmailsSent?.call(emailData, results);

      setState(() {
        _isSending = false;
      });

      // Determine status and message for the custom overlay
      String overlayTitle;
      String overlayMessage;
      IconData overlayIcon;
      Color overlayColor;

      final successCount = results.values.where((status) => status == 'Success').length;
      final totalCount = emailData.recipients.length;

      if (successCount == totalCount) {
        overlayTitle = 'Succès !';
        overlayMessage = 'Tous les e-mails ont été envoyés avec succès.';
        overlayIcon = Icons.check_circle_outline;
        overlayColor = Colors.green.shade600;
      } else if (successCount > 0) {
        overlayTitle = 'Envoi partiel';
        overlayMessage = '$successCount sur $totalCount e-mails ont été envoyés avec succès.';
        overlayIcon = Icons.warning_amber_outlined;
        overlayColor = Colors.orange.shade600;
      } else {
        overlayTitle = 'Échec de l\'envoi';
        overlayMessage = 'Aucun e-mail n\'a pu être envoyé.';
        overlayIcon = Icons.error_outline;
        overlayColor = Colors.red.shade600;
      }

      // Show custom status overlay
      await showGeneralDialog(
        context: context,
        barrierDismissible: false,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black.withOpacity(0.7),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              child: _buildStatusOverlay(overlayTitle, overlayMessage, overlayIcon, overlayColor),
            ),
          );
        },
      );

      // Clear fields after the status pop-up is dismissed
      _clearAll();

      // Then show the notification
      if (results.containsKey('error')) {
        widget.notificationService.showNotification('Erreur', results['error']!);
      } else {
        if (successCount == totalCount) {
          widget.notificationService.showNotification('Succès', 'Tous les e-mails ont été envoyés avec succès.');
        } else {
          widget.notificationService.showNotification('Partiel', '$successCount sur $totalCount e-mails ont été envoyés avec succès.');
        }
      }
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      widget.notificationService.showNotification('Erreur', 'Une erreur inattendue s\'est produite.');
    }
  }

  Widget _buildStatusOverlay(String title, String message, IconData icon, Color color) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.7), // Semi-transparent background
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade900,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss the dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color, // Button color matches status
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showValidationError(String message, FocusNode focusNode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
    focusNode.requestFocus();
    HapticFeedback.lightImpact();
  }

  void _clearAll() {
    setState(() {
      _recipients.clear();
      _attachments.clear();
      _subjectController.clear();
      _messageController.clear();
      _emailController.clear();
    });
    HapticFeedback.lightImpact();
  }

  bool get _isFormValid {
    return _recipients.isNotEmpty &&
           _subjectController.text.trim().isNotEmpty &&
           _messageController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isSending ? _buildProgressView() : _buildMainView(),
      floatingActionButton: _isSending ? null : _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isFormValid ? 1.0 : 0.0,
          child: FloatingActionButton.extended(
            onPressed: _isFormValid ? _sendEmails : null,
            backgroundColor: _isFormValid ? Theme.of(context).primaryColor : Colors.grey,
            foregroundColor: const Color.fromARGB(255, 4, 7, 172),
            elevation: _isFormValid ? 8 : 0,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Envoyer', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(Icons.send_rounded),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressView() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade700,
            Colors.blue.shade500,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.email_rounded,
                    color: Colors.white,
                    size: 120,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Envoi en cours...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vos e-mails sont en cours d\'envoi',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 200,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 180.0,
          floating: false,
          pinned: true,
          stretch: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'CursorMailer',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ],
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue.shade800,
                    Colors.blue.shade600,
                    Colors.purple.shade600,
                  ],
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.mail_outline_rounded,
                  size: 80,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _clearAll,
              tooltip: 'Tout effacer',
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildStepIndicator(),
                const SizedBox(height: 24),
                _buildRecipientsCard(),
                const SizedBox(height: 16),
                _buildContentCard(),
                const SizedBox(height: 16),
                _buildAttachmentsCard(),
                const SizedBox(height: 100), // Espace pour le FAB
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStepCircle(0, Icons.people_rounded, _recipients.isNotEmpty),
          _buildStepLine(_recipients.isNotEmpty),
          _buildStepCircle(1, Icons.subject_rounded, _subjectController.text.isNotEmpty && _messageController.text.isNotEmpty),
          _buildStepLine(_subjectController.text.isNotEmpty && _messageController.text.isNotEmpty),
          _buildStepCircle(2, Icons.attach_file_rounded, true),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, IconData icon, bool isCompleted) {
    final isActive = step <= _currentStep;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? Colors.green : (isActive ? Colors.blue : Colors.grey.shade300),
      ),
      child: Icon(
        isCompleted ? Icons.check_rounded : icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildStepLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? Colors.green : Colors.grey.shade300,
        margin: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildRecipientsCard() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimationController.value)),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.people_rounded, color: Colors.blue.shade700, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Destinataires',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              '${_recipients.length} adresse(s)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      style: kInputTextStyle,
                      // style: TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Collez les adresses e-mail ici (séparées par des virgules)',
                        prefixIcon: Icon(Icons.email_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _parseAndAddEmails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded),
                            const SizedBox(width: 8),
                            Text('Ajouter les e-mails', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
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
          ),
        );
      },
    );
  }

  Widget _buildContentCard() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimationController.value)),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.edit_document, color: Colors.green.shade700, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contenu',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              'Objet et message',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _subjectController,
                      focusNode: _subjectFocusNode,
                      style: kInputTextStyle,
                      decoration: InputDecoration(
                        labelText: 'Objet de l\'e-mail',
                        prefixIcon: Icon(Icons.subject_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      style: kInputTextStyle,
                      decoration: InputDecoration(
                        labelText: 'Message',
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: Icon(Icons.message_rounded),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        alignLabelWithHint: true,
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                      maxLines: 8,
                      onChanged: (value) => setState(() {}),
                    ),
                    if (_subjectController.text.isNotEmpty && _messageController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Contenu complété !',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentsCard() {
    return AnimatedBuilder(
      animation: _cardAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimationController.value)),
          child: Opacity(
            opacity: _cardAnimationController.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    Colors.grey.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.attach_file_rounded, color: Colors.orange.shade700, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pièces jointes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Text(
                              '${_attachments.length} fichier(s)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _pickFiles,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade700,
                          side: BorderSide(color: Colors.orange.shade300, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_rounded),
                            const SizedBox(width: 8),
                            Text('Ajouter des fichiers', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_attachments.isNotEmpty) ...[
                      Text(
                        'Fichiers attachés :',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._attachments.map((file) => _buildAttachmentItem(file)).toList(),
                    ] else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune pièce jointe',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Les fichiers apparaîtront ici',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttachmentItem(File file) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final fileSize = (file.lengthSync() / 1024).toStringAsFixed(1);
    final fileExtension = fileName.split('.').last.toLowerCase();
    
    IconData getFileIcon() {
      switch (fileExtension) {
        case 'pdf':
          return Icons.picture_as_pdf;
        case 'doc':
        case 'docx':
          return Icons.description;
        case 'xls':
        case 'xlsx':
          return Icons.table_chart;
        case 'ppt':
        case 'pptx':
          return Icons.slideshow;
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
          return Icons.image;
        case 'mp4':
        case 'avi':
        case 'mov':
          return Icons.video_file;
        case 'mp3':
        case 'wav':
          return Icons.audio_file;
        case 'zip':
        case 'rar':
          return Icons.archive;
        default:
          return Icons.insert_drive_file;
      }
    }

    Color getFileColor() {
      switch (fileExtension) {
        case 'pdf':
          return Colors.red.shade600;
        case 'doc':
        case 'docx':
          return Colors.blue.shade600;
        case 'xls':
        case 'xlsx':
          return Colors.green.shade600;
        case 'ppt':
        case 'pptx':
          return Colors.orange.shade600;
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'gif':
          return Colors.purple.shade600;
        case 'mp4':
        case 'avi':
        case 'mov':
          return Colors.indigo.shade600;
        case 'mp3':
        case 'wav':
          return Colors.pink.shade600;
        case 'zip':
        case 'rar':
          return Colors.brown.shade600;
        default:
          return Colors.grey.shade600;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: getFileColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            getFileIcon(),
            color: getFileColor(),
            size: 24,
          ),
        ),
        title: Text(
          fileName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.grey.shade800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$fileSize KB',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.close_rounded, color: Colors.red.shade400),
          onPressed: () => _removeAttachment(file),
          tooltip: 'Supprimer',
        ),
      ),
    );
  }
}