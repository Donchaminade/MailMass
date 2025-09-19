import 'package:flutter/material.dart';
import 'home_screen.dart'; // This will become the compose screen

class MainScreen extends StatefulWidget {
  final String? senderEmail;
  final String? senderPassword;

  const MainScreen({
    Key? key,
    this.senderEmail,
    this.senderPassword,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      HomeScreen(
        senderEmail: widget.senderEmail,
        senderPassword: widget.senderPassword,
      ),
      // Placeholder for other screens (e.g., History, Settings)
      const Center(child: Text('History Screen')),
      const Center(child: Text('Settings Screen')),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Compose',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.black,
      ),
    );
  }
}