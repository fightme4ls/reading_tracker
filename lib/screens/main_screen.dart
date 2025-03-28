import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'add_book_screen.dart';
import 'account_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Add the _onBookAdded method
  void _onBookAdded() {
    setState(() {
      _selectedIndex = 1;  // Switch to Library screen
    });
  }

  // List of screens, now passing the onBookAdded function to AddBookScreen
  static List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(),
      LibraryScreen(),
      AddBookScreen(onBookAdded: _onBookAdded),  // Passing the callback here
    ];
  }

  // Function to handle bottom navigation tab change
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AccountScreen()),
              );
            },
          ),
        ],
      )  // Change app bar title based on screen
          : _selectedIndex == 1
          ? AppBar(title: Text('Library'))
          : AppBar(title: Text('Add Book')),
      body: _pages[_selectedIndex],  // Display selected screen from _pages list
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Add'),
        ],
        currentIndex: _selectedIndex,  // Track selected index
        onTap: _onItemTapped,  // Change tab when tapped
      ),
    );
  }
}
