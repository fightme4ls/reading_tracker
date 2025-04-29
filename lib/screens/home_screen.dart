import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Book> bookBox;
  bool isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    bookBox = Hive.box<Book>('books');
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          isLoading = false;
        });
      }
    });
  }

  Future<void> _continueReading(BuildContext context, Book book) async {
    final now = DateTime.now();
    book.lastRead = now;
    await book.save();

    if (book.id != null && _currentUser != null) {
      FirebaseFirestore.instance.collection("books").doc(book.id).update({
        "lastRead": now.toIso8601String(),
      }).catchError((error) {
        print("Error updating lastRead in Firestore: $error");
        _showSnackbar('Failed to update read time remotely.');
      });
    }

    if (book.linkURL != null && book.linkURL!.isNotEmpty) {
      // Wait for navigation to complete and then refresh the UI when popped
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(url: book.linkURL!, book: book),
        ),
      );

      // Refresh state after coming back from WebView
      if (mounted) {
        setState(() {
          // This will refresh the UI with potentially updated book data
        });
      }
    } else {
      _showSnackbar('No link available for this book.');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showEditDialog(Book book) {
    TextEditingController titleController = TextEditingController(text: book.title);
    TextEditingController chapterController = TextEditingController(text: book.chapter.toString());
    TextEditingController linkController = TextEditingController(text: book.linkURL ?? '');
    TextEditingController imgController = TextEditingController(text: book.imageUrl ?? '');
    String selectedType = book.type;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Book'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: chapterController,
                  decoration: InputDecoration(
                    labelText: 'Chapter',
                    prefixIcon: Icon(Icons.bookmark),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 16),
                TextField(
                  controller: linkController,
                  decoration: InputDecoration(
                    labelText: 'Link (optional)',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: imgController,
                  decoration: InputDecoration(
                    labelText: 'Image Link (optional)',
                    prefixIcon: Icon(Icons.image),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButton<String>(
                  value: selectedType,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedType = newValue!;
                    });
                  },
                  items: <String>['Novel', 'Manga', 'Manhwa', 'Light Novel']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                book.title = titleController.text;
                book.chapter = int.tryParse(chapterController.text) ?? book.chapter;
                book.linkURL = linkController.text;
                book.imageUrl = imgController.text;
                book.type = selectedType;

                await book.save();
                _updateBookInFirestore(book);

                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _updateBookInFirestore(Book book) {
    if (book.id == null) return;

    FirebaseFirestore.instance
        .collection("books")
        .doc(book.id)
        .update({
      "title": book.title,
      "chapter": book.chapter,
      "linkURL": book.linkURL ?? '',
      "imageUrl": book.imageUrl ?? '',
      "type": book.type,
      "lastRead": book.lastRead?.toIso8601String() ?? DateTime.now().toIso8601String(),
    })
        .then((_) {
      print("Book updated in Firestore.");
    })
        .catchError((error) {
      print("Failed to update book in Firestore: $error");
      _showSnackbar("Failed to sync with cloud.");
    });
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Novel':
        return Colors.blue;
      case 'Manga':
        return Colors.red;
      case 'Manhwa':
        return Colors.purple;
      case 'Light Novel':
        return Colors.amber.shade800;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recently Read'),
        centerTitle: true,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
      body: ValueListenableBuilder<Box<Book>>(
        valueListenable: bookBox.listenable(),
        builder: (context, box, _) {
          if (isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (_currentUser == null) {
            return _buildNotLoggedIn();
          }

          final allBooks = box.values.where((book) => book.uid == _currentUser!.uid).toList();

          allBooks.sort((a, b) {
            final aTime = a.lastRead ?? DateTime(1900);
            final bTime = b.lastRead ?? DateTime(1900);
            return bTime.compareTo(aTime);
          });

          final recentBooks = allBooks.take(10).toList();

          if (recentBooks.isEmpty) {
            return _buildNoBooksAdded();
          }

          return _buildRecentBooksList(recentBooks);
        },
      ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Please log in to view your recently read.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNoBooksAdded() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_add_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Add some books!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            "Once you add books, your recently read will appear here.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBooksList(List<Book> books) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final book = books[index];
        return _buildBookCard(book);
      },
    );
  }

  Widget _buildBookCard(Book book) {
    String lastReadText = 'Never read';
    if (book.lastRead != null) {
      final now = DateTime.now();
      final difference = now.difference(book.lastRead!);

      if (difference.inMinutes < 1) {
        lastReadText = 'Just now';
      } else if (difference.inHours < 1) {
        lastReadText = '${difference.inMinutes} min ago';
      } else if (difference.inDays < 1) {
        lastReadText = '${difference.inHours} hours ago';
      } else if (difference.inDays < 7) {
        lastReadText = '${difference.inDays} days ago';
      } else {
        lastReadText = DateFormat('MMM d, y').format(book.lastRead!);
      }
    }

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showEditDialog(book), // Call edit dialog on tap
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                    ? Image.network(
                  book.imageUrl!,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 120,
                      color: Colors.grey.shade300,
                      child: Icon(Icons.broken_image, size: 40),
                    );
                  },
                )
                    : Container(
                  width: 80,
                  height: 120,
                  color: _getTypeColor(book.type).withOpacity(0.2),
                  child: Icon(Icons.book, size: 40, color: _getTypeColor(book.type)),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getTypeColor(book.type).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            book.type,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getTypeColor(book.type),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.bookmark_border, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          'Ch. ${book.chapter}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          lastReadText,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _continueReading(context, book),
                          icon: Icon(Icons.play_arrow, size: 16),
                          label: Text('Continue'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            minimumSize: Size(100, 32),
                            textStyle: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

//WebViewScreen
class WebViewScreen extends StatefulWidget {
  final String url;
  final Book book;

  WebViewScreen({required this.url, required this.book});

  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController _webViewController;
  String _currentUrl = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.url;
    _setupWebView();
  }

  void _setupWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              setState(() {
                _currentUrl = change.url!;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  void dispose() {
    // We no longer save on dispose
    super.dispose();
  }

  Future<void> _saveLastUrl() async {
    // Update book with current URL
    widget.book.linkURL = _currentUrl;
    widget.book.lastRead = DateTime.now();
    await widget.book.save();

    // Update in Firestore if available
    if (widget.book.id != null && FirebaseAuth.instance.currentUser != null) {
      FirebaseFirestore.instance.collection("books").doc(widget.book.id).update({
        "linkURL": _currentUrl,
        "lastRead": DateTime.now().toIso8601String(),
      }).catchError((error) {
        print("Error updating URL in Firestore: $error");
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reading progress saved'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currently Reading'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            tooltip: 'Save progress',
            onPressed: _saveLastUrl,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => _webViewController.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}