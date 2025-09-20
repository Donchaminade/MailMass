import 'package:flutter/material.dart';

import 'dart:io';
import 'package:cursormailer/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  final String? senderEmail;
  final String? senderPassword;
  final NotificationService notificationService;

  const SplashScreen({
    Key? key,
    this.senderEmail,
    this.senderPassword,
    required this.notificationService,
  }) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _logoPath;

  @override
  void initState() {
    super.initState();
    _loadDataAndNavigate();
  }

  Future<void> _loadDataAndNavigate() async {
    // Load logo path
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _logoPath = prefs.getString('logoPath');
    });

    // Simulate any other data loading or initialization here
    await Future.delayed(Duration(seconds: 3)); // Increased delay for better loading feel

    if (!mounted) return; // Check if the widget is still in the tree

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainScreen(
          senderEmail: widget.senderEmail,
          senderPassword: widget.senderPassword,
          notificationService: widget.notificationService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display logo or fallback
            _logoPath != null
                ? Image.file(
                    File(_logoPath!),
                    height: 180, // Slightly larger logo
                  )
                : Image.asset(
                    'assets/splash.png', // Fallback to a default splash image
                    height: 180,
                  ),
            SizedBox(height: 40), // Increased spacing
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor), // Golden yellow color
              strokeWidth: 5, // Thicker loading indicator
            ),
            SizedBox(height: 30), // Increased spacing
            Text(
              'Loading Application...',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white, // Ensure text is visible
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}