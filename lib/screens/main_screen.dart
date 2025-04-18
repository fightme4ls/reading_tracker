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
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _initializePages();
  }

  void _initializePages() {
    _pages = [
      HomeScreen(),
      LibraryScreen(),
      AddBookScreen(onBookAdded: _onBookAdded),
    ];
  }

  // Switch to Library tab when a book is added
  void _onBookAdded() {
    setState(() {
      _selectedIndex = 1;  // Switch to Library screen
    });
  }

  // Handle bottom navigation tab changes
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  AppBar _buildAppBar() {
    final titles = ['Home', 'Library', 'Add Book'];

    return AppBar(
      title: Text(titles[_selectedIndex]),
      centerTitle: true,
      elevation: 2,
      actions: [
        if (_selectedIndex == 0)  // Only show account button on Home screen
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AccountScreen()),
              );
            },
            tooltip: 'Account',
          ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}