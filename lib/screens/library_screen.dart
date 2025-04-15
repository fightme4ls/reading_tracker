import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late Box<Book> bookBox;
  String _sortOption = 'Title'; // Default sorting option
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isEditingMode = false; // Flag for multi-selection mode
  Set<Book> _selectedBooks = Set<Book>(); // Store selected books directly

  @override
  void initState() {
    super.initState();
    bookBox = Hive.box<Book>('books');
    _fetchBooksFromFirestore(); // Fetch Firestore books when app starts
  }

// Fetch books from Firestore and store them in Hive
  void _fetchBooksFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return; // If no user is logged in, return

    final userId = user.uid;
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('uid', isEqualTo: userId) // Only fetch books for logged-in user
        .get();

    // Clear existing Hive data to prevent duplicates
    await bookBox.clear();

    // Add books from Firestore to Hive
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final book = Book(
        id: doc.id, // Assign Firestore ID
        title: data['title'],
        type: data['type'],
        chapter: data['chapter'],
        imageUrl: data['imageUrl'],
        uid: data['uid'],
      );

      bookBox.add(book); // Store in Hive
    }

    setState(() {}); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditingMode ? 'Select items' : ''),
        actions: _isEditingMode
            ? []
            : [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('Sort by:   ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                DropdownButton<String>(
                  value: _sortOption,
                  onChanged: (newValue) {
                    setState(() {
                      _sortOption = newValue!;
                    });
                  },
                  items: ['Title', 'Chapter'].map((String value) {
                    return DropdownMenuItem<String>(value: value, child: Text(value));
                  }).toList(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isEditingMode = !_isEditingMode;
                if (!_isEditingMode) {
                  _selectedBooks.clear(); // Clear selection when exiting editing mode
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isEditingMode)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a book...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                },
              ),
            ),
          if (_isEditingMode && _selectedBooks.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Select items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          if (_isEditingMode && _selectedBooks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('${_selectedBooks.length} selected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: bookBox.listenable(),
              builder: (context, Box<Book> box, _) {
                // Get the current logged-in user UID
                final user = FirebaseAuth.instance.currentUser;
                final userId = user?.uid ?? '';

                // Filter books based on search query and the user's UID
                final books = box.values
                    .where((book) =>
                book.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
                    book.uid == userId) // Filter by user UID
                    .toList();

                // Sort books based on selected sort option
                if (_sortOption == 'Title') {
                  books.sort((a, b) => a.title.compareTo(b.title)); // Sort by title
                } else if (_sortOption == 'Chapter') {
                  books.sort((a, b) => a.chapter.compareTo(b.chapter)); // Sort by chapter
                }

                if (books.isEmpty) {
                  return Center(child: Text("No books found."));
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0), // Adjust padding from the edge
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,  // Number of tiles per row
                      crossAxisSpacing: 8.0,  // Reduced spacing between tiles horizontally
                      mainAxisSpacing: 8.0,   // Reduced spacing between tiles vertically
                      childAspectRatio: 0.7,  // Adjusted aspect ratio for better tile appearance
                    ),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return _buildBookTile(book);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _isEditingMode
          ? Stack(
        children: [
          Positioned(
            left: 44.0,
            bottom: 16.0,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _isEditingMode = false;
                        _selectedBooks.clear();
                      });
                    },
                    child: Icon(Icons.cancel),
                    backgroundColor: Colors.grey,
                    heroTag: 'cancel',
                  ),
                ),
                Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey, fontSize: 12.0),
                ),
              ],
            ),
          ),
          if (_selectedBooks.isNotEmpty)
            Positioned(
              right: 16.0,
              bottom: 16.0,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: FloatingActionButton(
                      onPressed: _deleteSelectedBooks,
                      child: Icon(Icons.delete),
                      backgroundColor: Colors.red,
                      heroTag: 'delete',
                    ),
                  ),
                  Text(
                    'Delete',
                    style: TextStyle(color: Colors.red, fontSize: 12.0),
                  ),
                ],
              ),
            ),
        ],
      )
          : null,
    );
  }

  Widget _buildBookTile(Book book) {
    bool isSelected = _selectedBooks.contains(book);

    return GestureDetector(
      onTap: () {
        if (_isEditingMode) {
          setState(() {
            if (isSelected) {
              _selectedBooks.remove(book);
            } else {
              _selectedBooks.add(book);
            }
          });
        } else {
          _showEditDialog(book);
        }
      },
      onLongPress: () {
        if (!_isEditingMode) {
          setState(() {
            _isEditingMode = true;
            _selectedBooks.add(book);
          });
        }
      },
      child: Opacity(
        opacity: isSelected ? 0.7 : 1.0,
        child: Card(
          elevation: isSelected ? 8.0 : 2.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  book.imageUrl != null
                      ? Image.network(book.imageUrl!, height: 200, width: 150, fit: BoxFit.cover)
                      : SizedBox.shrink(),
                  if (isSelected)
                    Positioned(
                      top: 8.0,
                      right: 8.0,
                      child: Container(
                        padding: EdgeInsets.all(1.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2.0),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.grey,
                          size: 30.0,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 8.0),
              // Wrap title in Flexible to prevent overflow and handle long text
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0), // Add horizontal padding
                  child: Text(
                    book.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis, // Adds ellipsis if text overflows
                    maxLines: 1, // Limit the number of lines
                  ),
                ),
              ),
              Text(
                'Chapter ${book.chapter}',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _showEditDialog(Book book) {
    TextEditingController chapterController = TextEditingController(text: book.chapter.toString());
    TextEditingController titleController = TextEditingController(text: book.title);
    TextEditingController linkController = TextEditingController(text: book.linkURL);
    TextEditingController imgController = TextEditingController(text: book.imageUrl);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Book'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: chapterController,
                decoration: InputDecoration(labelText: 'Chapter'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: linkController,
                decoration: InputDecoration(labelText: 'Link'),
              ),
              TextField(
                controller: imgController,
                decoration: InputDecoration(labelText: 'Image Link'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Update the local Hive data
                book.title = titleController.text;
                book.chapter = int.tryParse(chapterController.text) ?? book.chapter;
                book.linkURL = linkController.text;
                book.imageUrl = imgController.text;

                // Save the updated book locally
                await book.save();

                // Update the book in Firestore
                FirebaseFirestore.instance
                    .collection("books")
                    .doc(book.id) // Get the Firestore document using the book's ID
                    .update({
                  "title": book.title,
                  "chapter": book.chapter,
                  "linkURL": book.linkURL,
                  "imageUrl" : book.imageUrl,
                })
                    .then((_) {
                  print("Book updated in Firestore.");
                })
                    .catchError((error) {
                  print("Failed to update book in Firestore: $error");
                });

                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }


  void _deleteSelectedBooks() {
    for (Book book in _selectedBooks) {
      FirebaseFirestore.instance
          .collection("books")
          .doc(book.id)
          .delete()
          .then((_) {
        print("Book with id ${book.id} deleted from Firestore.");
      }).catchError((error) {
        print("Failed to delete book: $error");
      });

      book.delete();
    }

    setState(() {
      _selectedBooks.clear();
      _isEditingMode = false;
    });
  }
}
