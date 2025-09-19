import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MassMailApp());
}

class MassMailApp extends StatelessWidget {
  const MassMailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MassMail',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 2,
          centerTitle: true,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}