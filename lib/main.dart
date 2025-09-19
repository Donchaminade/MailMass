import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/main_screen.dart'; // Import MainScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required for dotenv.load()
  await dotenv.load(fileName: ".env");

  final senderEmail = dotenv.env['GMAIL_EMAIL'];
  final senderPassword = dotenv.env['GMAIL_PASSWORD'];

  runApp(CursorMailerApp(
    senderEmail: senderEmail,
    senderPassword: senderPassword,
  ));
}

class CursorMailerApp extends StatelessWidget {
  final String? senderEmail;
  final String? senderPassword;

  const CursorMailerApp({
    super.key,
    this.senderEmail,
    this.senderPassword,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CursorMailer',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.grey[850], // Slightly lighter grey for cards
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontSize: 57, fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
          labelLarge: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600), // For buttons
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
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
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Slightly rounded buttons
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[900], // Subtle background for text fields
          labelStyle: const TextStyle(color: Colors.white),
          hintStyle: TextStyle(color: Colors.grey[600]), // Lighter hint text
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 1.0),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 2.0), // Thicker border on focus
            borderRadius: BorderRadius.circular(8),
          ),
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 1.0),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      home: MainScreen( // Use MainScreen here
        senderEmail: senderEmail,
        senderPassword: senderPassword,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}