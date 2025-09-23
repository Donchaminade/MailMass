import 'package:cursormailer/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/main_screen.dart'; // Import MainScreen
import 'screens/splash.dart'; // Import SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for dotenv.load()
  await dotenv.load(fileName: ".env");

  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });

  final NotificationService notificationService = NotificationService();
  await notificationService.init();

  final senderEmail = dotenv.env['GMAIL_EMAIL'];
  final senderPassword = dotenv.env['GMAIL_PASSWORD'];

  runApp(CursorMailerApp(
    senderEmail: senderEmail,
    senderPassword: senderPassword,
    notificationService: notificationService,
  ));
}

class CursorMailerApp extends StatelessWidget {
  final String? senderEmail;
  final String? senderPassword;
  final NotificationService notificationService;

  const CursorMailerApp({
    super.key,
    this.senderEmail,
    this.senderPassword,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CursorMailer',
      theme: ThemeData(
        brightness: Brightness.dark, // Keep dark brightness for overall feel
        primaryColor: const Color.fromARGB(255, 7, 75, 223), // Pure Golden Yellow
        scaffoldBackgroundColor: const Color(0xFF0000A0), // Concentrated Blue
        cardColor: const Color(0xFF1A1A30), // Dark blue-grey for cards
        textTheme: TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontSize: 57, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
          labelLarge: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600), // For buttons, black text on yellow/gold
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF0000A0), // Concentrated Blue
          foregroundColor: Colors.white, // Ensures icons and text are white
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24, // Slightly larger app bar title
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(255, 11, 52, 233), // Pure Golden Yellow
            foregroundColor: Colors.black, // Black text on yellow/gold
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Slightly rounded buttons
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0A0A20), // Very dark blue for text fields
          labelStyle: const TextStyle(color: Colors.white),
          hintStyle: TextStyle(color: Colors.grey[600]), // Lighter hint text
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 1.0),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Color.fromARGB(255, 2, 85, 238), width: 2.0), // Golden yellow border on focus
            borderRadius: BorderRadius.circular(8),
          ),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 1.0),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: const Color(0xFF0000A0), // Concentrated Blue
          selectedItemColor: const Color.fromARGB(255, 255, 255, 255), // Golden Yellow for selected item
          unselectedItemColor: Colors.grey[600], // Muted grey for unselected items
          type: BottomNavigationBarType.fixed, // Ensures all labels are visible
        ),
      ),
      home: SplashScreen( // Use SplashScreen here
        senderEmail: senderEmail,
        senderPassword: senderPassword,
        notificationService: notificationService,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}