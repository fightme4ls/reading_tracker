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

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Recently Read'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('This page shows your recently read.'),
                SizedBox(height: 8),
                Text('If you set a link for your books and mangas, clicking "Continue" will open it for you and update your last read time.'),
                SizedBox(height: 8),
                Text('If no link is set, clicking "Continue" will just update your last read time.'),
                // Add more info here as needed for the Home Screen
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Switch to Library tab when a book is added
  void _onBookAdded() {
    setState(() {
      _selectedIndex = 1; // Switch to Library screen
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
    return AppBar(
      leading: _selectedIndex == 0
          ? IconButton(
        icon: Icon(Icons.info_outline),
        onPressed: () {
          _showInfoDialog(context);
        },
        tooltip: 'Home Screen Info',
      )
          : null,
      title: null,
      centerTitle: true,
      elevation: 2,
      actions: [
        IconButton(
          icon: Icon(Icons.account_circle),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AccountScreen()),
            );
          },
          tooltip: 'Account',
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(),
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