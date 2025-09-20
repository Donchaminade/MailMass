import 'package:cursormailer/models/email_history.dart';
import 'package:cursormailer/models/email_model.dart';
import 'package:flutter/cupertino.dart' show SizedBox;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  final String? senderEmail;
  final String? senderPassword;

  const MainScreen({Key? key, this.senderEmail, this.senderPassword})
      : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late AnimationController _bottomNavAnimationController;
  late List<Widget> _widgetOptions;
  final List<EmailHistoryEntry> _emailHistory = [];

  void _addEmailHistory(EmailModel email, Map<String, String> results) {
    final successCount =
        results.values.where((status) => status == 'Success').length;
    final totalCount = email.recipients.length;
    EmailSendStatus status;
    if (successCount == totalCount) {
      status = EmailSendStatus.success;
    } else if (successCount == 0) {
      status = EmailSendStatus.failed;
    } else {
      status = EmailSendStatus.partial;
    }

    setState(() {
      _emailHistory.insert(
        0,
        EmailHistoryEntry(
          email: email,
          timestamp: DateTime.now(),
          status: status,
          results: results,
        ),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _bottomNavAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _widgetOptions = <Widget>[
      HomeScreen(
        senderEmail: widget.senderEmail,
        senderPassword: widget.senderPassword,
        onEmailsSent: _addEmailHistory,
      ),
      _buildHistoryScreen(),
      _buildSettingsScreen(),
    ];

    // Start animations
    _fabAnimationController.forward();
    _bottomNavAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    _bottomNavAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      // Add haptic feedback for better UX
      HapticFeedback.lightImpact();

      setState(() {
        _selectedIndex = index;
      });

      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Main content with proper padding for bottom navigation
          Padding(
            padding: const EdgeInsets.only(bottom: 90), // Space for bottom nav
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              itemCount: _widgetOptions.length,
              itemBuilder: (context, index) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _widgetOptions[index],
                );
              },
            ),
          ),
          // Fixed bottom navigation
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildModernBottomNav(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(
        CurvedAnimation(
          parent: _bottomNavAnimationController,
          curve: Curves.easeOutCubic,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade100],
          ),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.7),
              blurRadius: 1,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.edit_rounded, 'Composer'),
            _buildNavItem(1, Icons.history_rounded, 'Historique'),
            _buildNavItem(2, Icons.settings_rounded, 'Paramètres'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade600, Colors.blue.shade700],
                )
              : null,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: isSelected ? 24 : 22,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.0,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryScreen() {
    // Variables pour stocker les vraies statistiques
    final int totalSent = _emailHistory.length;
    final int totalSuccess = _emailHistory
        .where((entry) => entry.status == EmailSendStatus.success)
        .length;
    final int totalFailed = _emailHistory
        .where((entry) => entry.status == EmailSendStatus.failed)
        .length;
    final int totalPartial = _emailHistory
        .where((entry) => entry.status == EmailSendStatus.partial)
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Center(
                child: Center(
                  child: const Text(
                    'Historique',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade600,
                      Colors.blue.shade400,
                      Colors.cyan.shade300,
                    ],
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 100, left: 16, right: 16),
                  child: Row(
                    children: [
                      _buildStatCard(
                        'Succès',
                        '$totalSuccess',
                        Colors.green.shade200,
                       
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Partiel',
                        '$totalPartial',
                        Colors.orange.shade200,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        'Échecs',
                        '$totalFailed',
                        Colors.red.shade200,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.filter_list_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => _showFilterDialog(),
                ),
              ),
            ],
          ),
          // Affichage conditionnel : vide si pas d'historique
          totalSent == 0
              ? SliverFillRemaining(child: _buildEmptyHistoryState())
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildHistoryCard(index),
                      childCount:
                          _emailHistory.length, // Sera remplacé par la vraie liste d'historique
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 64,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucun historique',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Vous n\'avez encore envoyé aucun e-mail.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Vos statistiques d\'envoi apparaîtront ici après votre premier envoi.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Commencez par composer un e-mail',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
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

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Filtrer l\'historique',
          style: TextStyle(color: Colors.grey.shade800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Tous les statuts', true),
            _buildFilterOption('Succès seulement', false),
            _buildFilterOption('Échecs seulement', false),
            Divider(color: Colors.grey.shade300),
            _buildFilterOption('Dernières 24 heures', false),
            _buildFilterOption('7 derniers jours', false),
            _buildFilterOption('30 derniers jours', true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Appliquer',
              style: TextStyle(color: Colors.blue.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title, bool selected) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
      ),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? Colors.blue.shade600 : Colors.grey.shade400,
      ),
      onTap: () {},
    );
  }

  Widget _buildHistoryCard(int index) {
    final entry = _emailHistory[index];
    IconData statusIcon;
    Color statusColor;
    String statusText;

    switch (entry.status) {
      case EmailSendStatus.success:
        statusIcon = Icons.check_circle_rounded;
        statusColor = Colors.green.shade600;
        statusText = 'Succès';
        break;
      case EmailSendStatus.failed:
        statusIcon = Icons.error_rounded;
        statusColor = Colors.red.shade600;
        statusText = 'Échec';
        break;
      case EmailSendStatus.partial:
        statusIcon = Icons.warning_rounded;
        statusColor = Colors.orange.shade600;
        statusText = 'Partiel';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () => _showEmailDetails(entry),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${entry.timestamp.day}/${entry.timestamp.month}/${entry.timestamp.year}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                entry.email.subject,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.email.recipients.length} destinataires',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showEmailDetails(EmailHistoryEntry entry) {
    final successCount =
        entry.results.values.where((status) => status == 'Success').length;
    final failedCount = entry.results.length - successCount -1;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Détails de l\'envoi',
          style: TextStyle(color: Colors.grey.shade800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Sujet', entry.email.subject),
              _buildDetailRow('Message', entry.email.message),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDetailStat('Succès', '$successCount', Colors.green.shade600),
                  _buildDetailStat('Échecs', '$failedCount', Colors.red.shade600),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Destinataires:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800),
              ),
              const SizedBox(height: 8),
              ...entry.results.entries.map((result) {
                if (result.key == 'summary') return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Icon(
                        result.value == 'Success'
                            ? Icons.check_circle
                            : Icons.error,
                        color: result.value == 'Success'
                            ? Colors.green.shade600
                            : Colors.red.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        result.key,
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _retryFailedEmails(Map<String, dynamic> data) {
    // Cette méthode sera implémentée quand il y aura de vraies données d'échec
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Réessayer les envois',
          style: TextStyle(color: Colors.grey.shade800),
        ),
        content: const Text('Aucun e-mail en échec à réessayer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Paramètres',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.shade600,
                      Colors.purple.shade400,
                      Colors.pink.shade300,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 100, left: 16, right: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'CursorMailer Pro',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.senderEmail ?? 'Non configuré',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Account Section
                _buildSettingsSection(
                  'Compte',
                  [
                    _buildSettingsItem(
                      Icons.email_rounded,
                      'Configuration e-mail',
                      'Paramètres SMTP et authentification',
                      onTap: () => _showEmailConfigDialog(),
                    ),
                    _buildSettingsItem(
                      Icons.security_rounded,
                      'Sécurité',
                      'Mots de passe et authentification',
                      onTap: () => _showSecurityDialog(),
                    ),
                    _buildSettingsItem(
                      Icons.backup_rounded,
                      'Sauvegarde',
                      'Synchronisation des données',
                      onTap: () => _showBackupDialog(),
                    ),
                  ] as List<Widget>,
                ),
                const SizedBox(height: 16),
                _buildSettingsSection(
                  'Application',
                  [
                    _buildSettingsItem(
                      Icons.notifications_rounded,
                      'Notifications',
                      'Alertes et rappels',
                      onTap: () => _showNotificationDialog(),
                    ),
                    _buildSettingsItem(
                      Icons.palette_rounded,
                      'Apparence',
                      'Thème et couleurs',
                      onTap: () => _showThemeDialog(),
                    ),
                    _buildSettingsItem(
                      Icons.language_rounded,
                      'Langue',
                      'Français',
                      onTap: () => _showLanguageDialog(),
                    ),
                  ] as List<Widget>,
                ),
                const SizedBox(height: 16),
                _buildSettingsSection(
                  'Support',
                  [
                    _buildSettingsItem(
                      Icons.help_rounded,
                      'Aide',
                      'Documentation et FAQ',
                      onTap: () => _showHelpDialog(),
                    ),
                    _buildSettingsItem(
                      Icons.info_rounded,
                      'À propos',
                      'Version 2.1.0',
                      onTap: () => _showAboutDialog(),
                    ),
                  ] as List<Widget>,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Email Configuration Dialog
  void _showEmailConfigDialog() {
    final TextEditingController smtpController = TextEditingController();
    final TextEditingController portController = TextEditingController();
    final TextEditingController emailController = TextEditingController(
      text: widget.senderEmail,
    );
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Configuration e-mail',
          style: TextStyle(color: Colors.grey.shade800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: smtpController,
                style: TextStyle(color: Colors.grey.shade800),
                decoration: InputDecoration(
                  labelText: 'Serveur SMTP',
                  hintText: 'smtp.gmail.com',
                  prefixIcon: Icon(Icons.dns, color: Colors.blue.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: portController,
                style: TextStyle(color: Colors.grey.shade800),
                decoration: InputDecoration(
                  labelText: 'Port',
                  hintText: '587',
                  prefixIcon: Icon(
                    Icons.settings_ethernet,
                    color: Colors.blue.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: TextStyle(color: Colors.grey.shade800),
                decoration: InputDecoration(
                  labelText: 'Adresse e-mail',
                  prefixIcon: Icon(Icons.email, color: Colors.blue.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                style: TextStyle(color: Colors.grey.shade800),
                decoration: InputDecoration(
                  labelText: 'Mot de passe d\'application',
                  prefixIcon: Icon(Icons.lock, color: Colors.blue.shade600),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Configuration sauvegardée avec succès !',
                  ),
                  backgroundColor: Colors.green.shade600,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Text(
              'Sauvegarder',
              style: TextStyle(color: Colors.blue.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // Security Dialog
  void _showSecurityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Paramètres de sécurité',
          style: TextStyle(color: Colors.grey.shade800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.fingerprint, color: Colors.blue.shade600),
              title: Text(
                'Authentification biométrique',
                style: TextStyle(color: Colors.grey.shade800),
              ),
              subtitle: Text(
                'Utiliser empreinte/Face ID',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              trailing: Switch(
                value: true,
                onChanged: (v) {},
                activeColor: Colors.blue.shade600,
              ),
            ),
            ListTile(
              leading: Icon(Icons.vpn_key, color: Colors.orange.shade600),
              title: Text(
                'Changer le mot de passe',
                style: TextStyle(color: Colors.grey.shade800),
              ),
              subtitle: Text(
                'Mettre à jour le mot de passe',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              onTap: () => _showChangePasswordDialog(),
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.green.shade600),
              title: Text(
                'Historique des connexions',
                style: TextStyle(color: Colors.grey.shade800),
              ),
              subtitle: Text(
                'Voir les connexions récentes',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              // onTap: () => _showLoginHistoryDialog(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Changer le mot de passe',
          style: TextStyle(color: Colors.grey.shade800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: TextStyle(color: Colors.grey.shade800),
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: Colors.grey.shade800),
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              style: TextStyle(color: Colors.grey.shade800),
              decoration: InputDecoration(
                labelText: 'Confirmer le nouveau mot de passe',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Mettre à jour',
              style: TextStyle(color: Colors.blue.shade600),
            ),
          ),
        ],
      ),
    );
  }

  // void _showLoginHistoryDialog() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       backgroundColor: Colors.white,
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       title: Text(
  //         'Historique des connexions',
  //         style: TextStyle(color: Colors.grey.shade800),
  //       ),
  //       content: SizedBox(
  //         width: double.maxFinite,
  //         height: 300,
  //         child: ListView(
  //           children: [
  //             _buildLoginHistoryItem(
  //               'PC Windows',
  //               'Maintenant',
  //               Icons.computer,
  //               Colors.green,
  //             ),
  //             _buildLoginHistoryItem(
  //               'iPhone 12',
  //               'Il y a 2 heures',
  //               Icons.phone_iphone,
  //               Colors.blue,
  //             ),
  //             _buildLoginHistoryItem(
  //               'MacBook Pro',
  //               'Hier',
  //               Icons.laptop_mac,
  //               Colors.orange,
  //             ),
  //           ],
  //         ),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text(
  //             'Fermer',
  //             style: TextStyle(color: Colors.grey.shade600),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildLoginHistoryItem(
    String device,
    String time,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(device, style: TextStyle(color: Colors.grey.shade800)),
      subtitle: Text(time, style: TextStyle(color: Colors.grey.shade600)),
      trailing: const Icon(Icons.check_circle, color: Colors.green, size: 16),
    );
  }

  // Other Dialog Methods
  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sauvegarde et synchronisation',
          style: TextStyle(color: Colors.grey.shade800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.cloud_upload, color: Colors.blue.shade600),
              title: Text(
                'Sauvegarde automatique',
                style: TextStyle(color: Colors.grey.shade800),
              ),
              subtitle: Text(
                'Sauvegarder quotidiennement',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              trailing: Switch(
                value: true,
                onChanged: (v) {},
                activeColor: Colors.blue.shade600,
              ),
            ),
            ListTile(
              leading: Icon(Icons.sync, color: Colors.green.shade600),
              title: Text(
                'Synchronisation',
                style: TextStyle(color: Colors.grey.shade800),
              ),
              subtitle: Text(
                'Dernière sync: il y a 2 heures',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.download, color: Colors.orange.shade600),
              title: Text(
                'Sauvegarde manuelle',
                style: TextStyle(color: Colors.grey.shade800),
              ),
              subtitle: Text(
                'Créer une sauvegarde maintenant',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Sauvegarde créée avec succès !'),
                    backgroundColor: Colors.green.shade600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Notifications',
          style: TextStyle(color: Colors.grey.shade800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNotificationToggle('E-mail envoyé avec succès', true),
            _buildNotificationToggle('Échecs d\'envoi', true),
            _buildNotificationToggle('Résumé quotidien', false),
            _buildNotificationToggle('Rapports hebdomadaires', true),
            _buildNotificationToggle('Mises à jour', false),
            Divider(color: Colors.grey.shade300),
            ListTile(
              leading: Icon(Icons.volume_up, color: Colors.blue.shade600),
              title: Text('Son', style: TextStyle(color: Colors.grey.shade800)),
              trailing: DropdownButton<String>(
                value: 'Par défaut',
                dropdownColor: Colors.white,
                items: ['Par défaut', 'Silencieux', 'Carillon']
                    .map(
                      (e) => DropdownMenuItem(
                        value: e,
                        child: Text(
                          e,
                          style: TextStyle(color: Colors.grey.shade800),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(String title, bool value) {
    return ListTile(
      title: Text(title, style: TextStyle(color: Colors.grey.shade800)),
      trailing: Switch(
        value: value,
        onChanged: (v) {},
        activeColor: Colors.blue.shade600,
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Paramètres d\'apparence',
          style: TextStyle(color: Colors.grey.shade800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption('Mode sombre', false),
            _buildThemeOption('Mode clair', true),
            _buildThemeOption('Système par défaut', false),
            Divider(color: Colors.grey.shade300),
            ListTile(
              leading: Icon(Icons.color_lens, color: Colors.blue.shade600),
              title: Text(
                'Couleur d\'accent',
                style: TextStyle(color: Colors.grey.shade800),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildColorCircle(Colors.blue, true),
                  _buildColorCircle(Colors.green, false),
                  _buildColorCircle(Colors.orange, false),
                  _buildColorCircle(Colors.purple, false),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String title, bool selected) {
    return ListTile(
      title: Text(title, style: TextStyle(color: Colors.grey.shade800)),
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? Colors.blue.shade600 : Colors.grey.shade400,
      ),
      onTap: () {},
    );
  }

  Widget _buildColorCircle(Color color, bool selected) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: Colors.grey.shade800, width: 2)
            : null,
      ),
    );
  }

  // Placeholder methods for other dialogs
  void _showLanguageDialog() => _showComingSoonDialog('Paramètres de langue');
  void _showHelpDialog() => _showComingSoonDialog('Aide et documentation');
  void _showAboutDialog() =>
      _showComingSoonDialog('À propos de l\'application');

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(feature, style: TextStyle(color: Colors.grey.shade800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction, color: Colors.orange.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              'Cette fonctionnalité arrive bientôt !',
              style: TextStyle(color: Colors.grey.shade800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Restez connecté pour les mises à jour.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.blue.shade600)),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.blue.shade600, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
          ],
        ),
      ),
    );
  }
}
