import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import '../models/book.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AccountScreen extends StatefulWidget {
  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _importController = TextEditingController();

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

    _importController.addListener(_onImportTextChanged);
  }

  @override
  void dispose() {
    _importController.removeListener(_onImportTextChanged);
    _importController.dispose();
    super.dispose();
  }

  void _onImportTextChanged() {
    final String currentText = _importController.text;
    String transformedText = currentText.toLowerCase().trim().split('\n').map((line) {
      if (line.contains('finished chapter')) {
        return line.replaceAll(' finished chapter ', ' ').replaceAll(' finished chapter', '').trim();
      } else if (line.contains('chapter') && line.contains('finished')) {
        final regExp = RegExp(r'(chapter\s*\d+)\s*finished');
        if (regExp.hasMatch(line)) {
          return line.replaceAllMapped(regExp, (match) {
            return match.group(1)!.replaceAll('chapter', '').trim();
          }).trim();
        }
      } else if (line.contains('finished')) {
        return line.replaceAll(' finished ', ' 0 ').replaceAll(' finished', ' 0').trim();
      } else if (line.contains('not started')) {
        return line.replaceAll(' not started ', ' 0 ').replaceAll(' not started', ' 0').trim();
      } else {
        return line.trim();
      }
    }).join('\n');

    if (transformedText != currentText) {
      _importController.value = TextEditingValue(
        text: transformedText,
        selection: TextSelection.collapsed(offset: transformedText.length),
      );
    }
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
        print("Error deleting books from Firestore: $error");
        _showErrorSnackbar('Failed to delete associated books from Firestore.');
        return;
      });

      final bookBox = Hive.box<Book>('books');
      final keysToDelete = bookBox.keys.cast<int>().where((key) => bookBox.get(key)?.uid == uid).toList();
      await bookBox.deleteAll(keysToDelete);
      print("Deleted ${keysToDelete.length} books from local storage.");

      await currentUser?.delete();
      await FirebaseAuth.instance.signOut();
      _showSnackbar('Account deleted.');

      Navigator.push(
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

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<Map<String, dynamic>> _searchBook(String title) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.jikan.moe/v4/manga?q=$title&limit=1'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          String apiTitle = data['data'][0]['title'] ?? '';
          return {'title': apiTitle, ...data['data'][0]};
        }
      }
    } catch (e) {
      print('Error searching book: $e');
    }
    return {};
  }

  // Future<String?> _searchMangaDex(String title) async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('https://api.mangadex.org/manga?title=$title&limit=1'),
  //     );
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       if (data['data'] != null && data['data'].isNotEmpty) {
  //         String mangaId = data['data'][0]['id'];
  //         return 'https://mangadex.org/title/$mangaId';
  //       }
  //     } else {
  //       print('MangaDex API error: ${response.statusCode}');
  //     }
  //   } catch (e) {
  //     print('Error searching MangaDex: $e');
  //   }
  //   return null;
  // }

  Future<void> _importBooks(String bookList) async {
    if (currentUser == null) {
      _showErrorSnackbar('Please log in to import books.');
      return;
    }

    List<String> lines = bookList.trim().split('\n');
    int importedCount = 0;
    List<String> failedImports = [];
    final bookBox = Hive.box<Book>('books');

    for (String line in lines) {
      try {
        String title = '';
        int chapter = 0;
        line = line.trim();
        List<String> parts = line.split(' ');

        if (parts.isNotEmpty) {
          String? potentialChapter = parts.lastOrNull;
          if (potentialChapter != null && int.tryParse(potentialChapter) != null) {
            chapter = int.parse(potentialChapter);
            title = parts.sublist(0, parts.length - 1).join(' ').trim();
          } else {
            title = line.trim();
            if (line.toLowerCase().contains('finished') || line.toLowerCase().contains('not started')) {
              chapter = 0;
              title = line.toLowerCase().replaceAll('finished', '').replaceAll('not started', '').trim();
            }
          }
        }

        if (title.isNotEmpty) {
          Map<String, dynamic> searchResult = await _searchBook(title);
          String apiTitle = searchResult['title'] ?? title;
          String imageUrl = "https://placehold.co/600x400/png/?text=Manual\\nEntry&font=Oswald";
          String type = "Novel";
          //String? mangaDexLink = await _searchMangaDex(title);
          const String mangaDexLink = ""; // Set a default empty string

          if (searchResult.isNotEmpty && searchResult['images']?['jpg']?['image_url'] != null) {
            imageUrl = searchResult['images']['jpg']['image_url'];
          }
          if (searchResult.isNotEmpty && searchResult['type'] != null) {
            type = searchResult['type'];
          }

          final now = DateTime.now();

          final docRef = await FirebaseFirestore.instance.collection("books").add({
            "uid": currentUser!.uid,
            "title": apiTitle,
            "chapter": chapter,
            "type": type,
            "imageUrl": imageUrl,
            "linkURL": mangaDexLink ?? "",
            "lastRead": now.toIso8601String(),
          });

          final newBook = Book(
            title: apiTitle,
            type: type,
            chapter: chapter,
            imageUrl: imageUrl,
            linkURL: mangaDexLink ?? "",
            uid: currentUser!.uid,
            lastRead: now,
            id: docRef.id,
          );
          await bookBox.add(newBook);

          importedCount++;
        } else {
          failedImports.add(line);
        }
      } catch (e) {
        print("Error importing line: $line - $e");
        failedImports.add(line);
      }
    }

    String message = '$importedCount books imported successfully.';
    if (failedImports.isNotEmpty) {
      message += '\nFailed to import ${failedImports.length} books: ${failedImports.join(", ")}';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Import Books'),
          content: SingleChildScrollView(
            child: TextField(
              controller: _importController,
              maxLines: 10,
              decoration: InputDecoration(
                hintText:
                "Paste your book list here. Each book should be on a new line. "
                    "Please be aware that some books will not be added properly."
                    "The app will try to automatically format it. For optimal results, "
                    "it should be formatted like: tokyo ghoul 7",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Import'),
              onPressed: () {
                _importBooks(_importController.text);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                        (Route<dynamic> route) => false,
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
                _buildImportBooksButton(),
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
    );
  }

  Widget _buildImportBooksButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _showImportDialog(context);
      },
      icon: Icon(Icons.upload_file),
      label: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          'Import Books',
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

  Widget _buildUserInfoButton() {
    return ElevatedButton.icon(
      onPressed: () {
        User? user = FirebaseAuth.instance.currentUser;
        String uid = user?.uid ?? '';
        String message = user != null
            ? 'Logged in as: ${user.email}'
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
                final data = element.data();
                final lastReadTimestamp = data['lastRead'];
                String lastReadFormatted = lastReadTimestamp != null
                    ? ' (Last Read: ${DateTime.parse(lastReadTimestamp).toLocal().toString().split('.').first})'
                    : '';
                bookList += '- ${data['title']} (Chapter ${data['chapter']})$lastReadFormatted\n';
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

  Widget _buildLoginButton() {
    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
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


}