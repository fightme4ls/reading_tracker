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
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .delete()
          .catchError((error) {
        print("Error deleting user document: $error");
      });

      await currentUser?.delete();
      FirebaseAuth.instance.signOut();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (error) {
      print("Error deleting account: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete the account: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account Settings'),
        centerTitle: true,
        actions: [
          // Logout icon on the top right
          if (currentUser != null) ...[
            IconButton(
              icon: Icon(Icons.exit_to_app), // Icon for logging out (you can change it)
              onPressed: () {
                FirebaseAuth.instance.signOut().then((_) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                });
              },
            ),
          ]
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              SizedBox(height: 30),

              // If user is logged in, show these options
              if (currentUser != null) ...[
                ElevatedButton(
                  onPressed: () {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      FirebaseFirestore.instance
                          .collection("books")
                          .where("uid", isEqualTo: user.uid)
                          .get()
                          .then((querySnapshot) {
                        print("Successfully listed books for the current user.");
                        querySnapshot.docs.forEach((element) {
                          print("Title: " + element.data()['title']);
                          print("Chapter: " + element.data()['chapter'].toString());
                        });
                      }).catchError((error) {
                        print("Failed to list books for the current user.");
                        print(error);
                      });
                    } else {
                      print("No user is logged in.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'List Books',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    User? user = FirebaseAuth.instance.currentUser;
                    String uid = user?.uid ?? '';
                    String message = user != null
                        ? 'Logged in as: ${user.email}\nUID: $uid'
                        : 'Log in first!';

                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('User Info'),
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
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Show User Information',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Delete Account'),
                          content: Text(
                              'Are you sure you want to delete your account and all associated data? This action is permanent.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _deleteUserAccount();
                              },
                              child: Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Delete Account',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(height: 16),
              ],

              // If no user is logged in
              if (currentUser == null) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    'Login or Sign Up',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],

              SizedBox(height: 30),
            ],
          ),
        ),
      ),

      // Home icon button at the bottom left
      floatingActionButton: FloatingActionButton(
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
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
