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
  // Book data & state
  late Box<Book> bookBox;
  String _sortOption = 'Title';
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Selection mode state
  bool _isEditingMode = false;
  Set<Book> _selectedBooks = Set<Book>();

  @override
  void initState() {
    super.initState();
    bookBox = Hive.box<Book>('books');
    _fetchBooksFromFirestore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _isEditingMode ? _buildEditModeActions() : null,
    );
  }

  AppBar _buildAppBar() {
    if (_isEditingMode) {
      return AppBar(
        title: Text(_selectedBooks.isEmpty
            ? 'Select items'
            : '${_selectedBooks.length} selected'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            setState(() {
              _isEditingMode = false;
              _selectedBooks.clear();
            });
          },
        ),
      );
    } else {
      return AppBar(
        title: Text('Library'),
        actions: [
          _buildSortDropdown(),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () {
              setState(() {
                _isEditingMode = true;
              });
            },
          ),
        ],
      );
    }
  }

  Widget _buildSortDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: DropdownButton<String>(
        underline: Container(),
        icon: Icon(Icons.sort),
        value: _sortOption,
        onChanged: (newValue) {
          setState(() {
            _sortOption = newValue!;
          });
        },
        items: ['Title', 'Chapter'].map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Row(
              children: [
                Icon(value == 'Title' ? Icons.sort_by_alpha : Icons.format_list_numbered, size: 16),
                SizedBox(width: 8),
                Text(value),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        if (!_isEditingMode) _buildSearchBar(),
        Expanded(
          child: ValueListenableBuilder(
            valueListenable: bookBox.listenable(),
            builder: (context, Box<Book> box, _) {
              return _buildBookGrid(box);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for a book...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade200,
          contentPadding: EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
      ),
    );
  }

  Widget _buildBookGrid(Box<Book> box) {
    // Get the current logged-in user UID
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    // Filter books based on search query and user's UID
    final books = box.values
        .where((book) =>
    book.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
        book.uid == userId)
        .toList();

    // Sort books based on selected sort option
    if (_sortOption == 'Title') {
      books.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sortOption == 'Chapter') {
      books.sort((a, b) => a.chapter.compareTo(b.chapter));
    }

    if (books.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.65,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return _buildBookTile(book);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No books found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? "Try a different search term"
                : "Add books to your library",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
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
      child: Card(
        elevation: isSelected ? 6.0 : 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isSelected
              ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
              : BorderSide.none,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Book cover image
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                        ? Image.network(
                      book.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: Icon(Icons.broken_image, size: 50),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey.shade300,
                      child: Icon(Icons.book, size: 50),
                    ),
                  ),
                  // Selection indicator
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Book info
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.bookmark_border, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        'Ch. ${book.chapter}',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getTypeColor(book.type).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          book.type,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getTypeColor(book.type),
                            fontWeight: FontWeight.w500,
                          ),
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
    );
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

  Widget _buildEditModeActions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_selectedBooks.isNotEmpty)
            FloatingActionButton.extended(
              onPressed: _deleteSelectedBooks,
              backgroundColor: Colors.red,
              icon: Icon(Icons.delete),
              label: Text('Delete'),
              heroTag: 'delete',
            ),
        ],
      ),
    );
  }

  void _showEditDialog(Book book) {
    TextEditingController titleController = TextEditingController(text: book.title);
    TextEditingController chapterController = TextEditingController(text: book.chapter.toString());
    TextEditingController linkController = TextEditingController(text: book.linkURL ?? '');
    TextEditingController imgController = TextEditingController(text: book.imageUrl ?? '');

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
                // Update the local Hive data
                book.title = titleController.text;
                book.chapter = int.tryParse(chapterController.text) ?? book.chapter;
                book.linkURL = linkController.text;
                book.imageUrl = imgController.text;

                // Save the updated book locally
                await book.save();

                // Update the book in Firestore
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
    })
        .then((_) {
      print("Book updated in Firestore.");
    })
        .catchError((error) {
      print("Failed to update book in Firestore: $error");
      _showErrorSnackbar("Failed to sync with cloud.");
    });
  }

  void _deleteSelectedBooks() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Books'),
        content: Text('Are you sure you want to delete ${_selectedBooks.length} ${_selectedBooks.length == 1 ? 'book' : 'books'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _performDelete() {
    for (Book book in _selectedBooks) {
      if (book.id != null) {
        FirebaseFirestore.instance
            .collection("books")
            .doc(book.id)
            .delete()
            .then((_) {
          print("Book with id ${book.id} deleted from Firestore.");
        }).catchError((error) {
          print("Failed to delete book: $error");
        });
      }
      book.delete();
    }

    setState(() {
      _selectedBooks.clear();
      _isEditingMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Books deleted successfully'))
    );
  }

  void _fetchBooksFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('uid', isEqualTo: userId)
          .get();

      // Clear existing Hive data to prevent duplicates
      await bookBox.clear();

      // Add books from Firestore to Hive
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final book = Book(
          id: doc.id,
          title: data['title'] ?? 'Untitled',
          type: data['type'] ?? 'Novel',
          chapter: data['chapter'] ?? 1,
          imageUrl: data['imageUrl'],
          linkURL: data['linkURL'],
          uid: data['uid'],
        );

        bookBox.add(book);
      }

      setState(() {});
    } catch (e) {
      print("Error fetching books: $e");
      _showErrorSnackbar("Failed to load books from cloud.");
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}