import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart'; // Import the login page
import 'main_screen.dart';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() {
          currentUser = user;
        });
      }
    });
  }

  Future<void> _deleteUserAccount() async {
    try {
      String uid = currentUser?.uid ?? '';
      // Delete associated books
      await FirebaseFirestore.instance
          .collection('books')
          .where('uid', isEqualTo: uid)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.delete();
        }
      }).catchError((error) {
        print("Error deleting books: $error");
        _showErrorSnackbar('Failed to delete associated books.');
        return;
      });

      // Delete user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .delete()
          .catchError((error) {
        print("Error deleting user document: $error");
        _showErrorSnackbar('Failed to delete user information.');
        return;
      });

      // Delete Firebase Auth user
      await currentUser?.delete();
      await FirebaseAuth.instance.signOut();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (error) {
      print("Error deleting account: $error");
      _showErrorSnackbar('Failed to delete the account: $error');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Settings'),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
        actions: [
          if (currentUser != null)
            IconButton(
              icon: Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: () {
                FirebaseAuth.instance.signOut().then((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 30),
              if (currentUser != null) ...[
                _buildUserInfoButton(),
                SizedBox(height: 16),
                _buildListBooksButton(),
                SizedBox(height: 16),
                _buildDeleteAccountButton(),
                SizedBox(height: 32),
              ],
              if (currentUser == null) ...[
                _buildLoginButton(),
                SizedBox(height: 32),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: _buildHomeButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  // Button to show user info
  Widget _buildUserInfoButton() {
    return ElevatedButton.icon(
      onPressed: () {
        User? user = FirebaseAuth.instance.currentUser;
        String uid = user?.uid ?? '';
        String message = user != null
            ? 'Logged in as: ${user.email}\nUID: $uid'
            : 'Please log in to see your information.';

        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('User Information'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      },
      icon: Icon(Icons.person),
      label: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          'Show User Information',
          style: TextStyle(fontSize: 16),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    );
  }

  // Button to list books
  Widget _buildListBooksButton() {
    return ElevatedButton.icon(
      onPressed: () {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          FirebaseFirestore.instance
              .collection("books")
              .where("uid", isEqualTo: user.uid)
              .get()
              .then((querySnapshot) {
            if (querySnapshot.docs.isNotEmpty) {
              String bookList = 'Your Books:\n';
              querySnapshot.docs.forEach((element) {
                bookList += '- ${element.data()['title']} (Chapter ${element.data()['chapter']})\n';
              });
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Your Books'),
                  content: SingleChildScrollView(child: Text(bookList)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('OK'),
                    ),
                  ],
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('You haven\'t added any books yet.')),
              );
            }
          }).catchError((error) {
            print("Failed to list books for the current user: $error");
            _showErrorSnackbar('Failed to retrieve your book list.');
          });
        } else {
          _showErrorSnackbar('Please log in to see your books.');
        }
      },
      icon: Icon(Icons.library_books),
      label: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          'List My Books',
          style: TextStyle(fontSize: 16),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    );
  }

  // Button to delete user account
  Widget _buildDeleteAccountButton() {
    return ElevatedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Delete Account', style: TextStyle(color: Colors.red.shade400)),
              content: Text(
                'Are you sure you want to delete your account and all associated data? This action is permanent.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancel', style: TextStyle(fontSize: 16)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteUserAccount();
                  },
                  child: Text('Delete', style: TextStyle(color: Colors.red.shade400, fontSize: 16)),
                ),
              ],
            );
          },
        );
      },
      icon: Icon(Icons.delete_forever, color: Colors.white),
      label: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          'Delete Account',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
    );
  }

  // Button to login or sign up if no user is logged in
  Widget _buildLoginButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      },
      icon: Icon(Icons.login),
      label: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          'Login or Sign Up',
          style: TextStyle(fontSize: 16),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
      ),
    );
  }

  // Home button in the bottom left corner
  Widget _buildHomeButton() {
    return FloatingActionButton(
      onPressed: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      },
      backgroundColor: Colors.blueAccent,
      child: Icon(
        Icons.home,
        size: 30,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}