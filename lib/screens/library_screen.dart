import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/book_sync_service.dart';

class LibraryScreen extends StatefulWidget {
  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with WidgetsBindingObserver {
  late Box<Book> bookBox;
  String _sortOption = 'Title';
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  bool _isCardView = false;
  static const String _viewPreferenceKey = 'library_view_preference';

  bool _isEditingMode = false;
  Set<Book> _selectedBooks = Set<Book>();

  final BookSyncService _syncService = BookSyncService();

  @override
  void initState() {
    super.initState();
    bookBox = Hive.box<Book>('books');
    _loadViewPreference();
    WidgetsBinding.instance.addObserver(this);
    _refreshBooks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshBooks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshBooks();
    }
  }

  Future<void> _loadViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCardView = prefs.getBool(_viewPreferenceKey) ?? true;
    });
  }

  Future<void> _refreshBooks() async {
    if (FirebaseAuth.instance.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    await _syncService.syncBooksFromFirestore();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _isEditingMode && _selectedBooks.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _deleteSelectedBooks,
        backgroundColor: Colors.red,
        icon: Icon(Icons.delete),
        label: Text('Delete'),
        heroTag: 'delete',
      )
          : null,
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
          _buildViewToggle(),
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

  Widget _buildViewToggle() {
    return IconButton(
      icon: Icon(_isCardView ? Icons.view_list : Icons.grid_view),
      tooltip: _isCardView ? 'Switch to List View' : 'Switch to Card View',
      onPressed: () async {
        setState(() {
          _isCardView = !_isCardView;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_viewPreferenceKey, _isCardView);
      },
    );
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
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : ValueListenableBuilder(
            valueListenable: bookBox.listenable(),
            builder: (context, Box<Book> box, _) {
              return _isCardView ? _buildBookGrid(box) : _buildBookList(box);
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
          hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)),
          prefixIcon: Icon(Icons.search, color: Theme.of(context).iconTheme.color),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: EdgeInsets.symmetric(vertical: 0),
        ),
        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
        onChanged: (query) {
          setState(() {
            _searchQuery = query;
          });
        },
      ),
    );
  }

  List<Book> _getFilteredAndSortedBooks() {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';

    final books = bookBox.values
        .where((book) =>
    book.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
        book.uid == userId)
        .toList();

    if (_sortOption == 'Title') {
      books.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sortOption == 'Chapter') {
      books.sort((a, b) => a.chapter.compareTo(b.chapter));
    }

    return books;
  }

  Widget _buildBookGrid(Box<Book> box) {
    final books = _getFilteredAndSortedBooks();

    if (books.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _refreshBooks();
        _showSyncSnackbar("Synced to cloud");
      },
      child: Padding(
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
            return _buildBookCard(book);
          },
        ),
      ),
    );
  }

  Widget _buildBookList(Box<Book> box) {
    final books = _getFilteredAndSortedBooks();

    if (books.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _refreshBooks();
        _showSyncSnackbar("Synced to cloud");
      },
      child: ListView.separated(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        itemCount: books.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final book = books[index];
          return _buildBookListItem(book);
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

  Widget _buildBookCard(Book book) {
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
        color: Theme.of(context).cardColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    child: book.imageUrl != null && book.imageUrl!.isNotEmpty
                        ? Image.network(
                      book.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child: Icon(Icons.broken_image, size: 50, color: Theme.of(context).iconTheme.color),
                        );
                      },
                    )
                        : Container(
                      color: Colors.grey.shade300,
                      child: Icon(Icons.book, size: 50, color: Theme.of(context).iconTheme.color),
                    ),
                  ),
                  if (isSelected)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
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
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.bookmark_border, size: 16, color: Theme.of(context).iconTheme.color),
                      SizedBox(width: 4),
                      Text(
                        'Ch. ${book.chapter}',
                        style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12),
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

  Widget _buildBookListItem(Book book) {
    bool isSelected = _selectedBooks.contains(book);

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
      tileColor: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: Theme.of(context).primaryColor, width: 1)
            : BorderSide.none,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getTypeColor(book.type).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            book.title.isNotEmpty ? book.title[0].toUpperCase() : '?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getTypeColor(book.type),
              fontSize: 18,
            ),
          ),
        ),
      ),
      title: Text(
        book.title,
        style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodyLarge?.color),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        book.type,
        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Ch. ${book.chapter}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
            ),
        ],
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

  void _showEditDialog(Book book) {
    TextEditingController titleController = TextEditingController(text: book.title);
    TextEditingController chapterController = TextEditingController(text: book.chapter.toString());
    TextEditingController linkController = TextEditingController(text: book.linkURL ?? '');
    TextEditingController imgController = TextEditingController(text: book.imageUrl ?? '');
    String _selectedType = book.type;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
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
                      value: _selectedType,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedType = newValue!;
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
                    book.type = _selectedType;

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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Book updated successfully.'))
      );
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

  // void _fetchBooksFromFirestore() async {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user == null) return;
  //
  //   final userId = user.uid;
  //
  //   try {
  //     final QuerySnapshot snapshot = await FirebaseFirestore.instance
  //         .collection('books')
  //         .where('uid', isEqualTo: userId)
  //         .get();
  //
  //     for (var doc in snapshot.docs) {
  //       final data = doc.data() as Map<String, dynamic>;
  //
  //       DateTime? lastRead;
  //       if (data['lastRead'] != null) {
  //         try {
  //           lastRead = DateTime.parse(data['lastRead']);
  //         } catch (e) {
  //           print("Error parsing lastRead date: $e");
  //         }
  //       }
  //
  //       final existingBookIndex = bookBox.values.toList().indexWhere((b) => b.id == doc.id);
  //
  //       if (existingBookIndex != -1) {
  //         final existingBook = bookBox.getAt(existingBookIndex)!;
  //         existingBook.title = data['title'] ?? existingBook.title;
  //         existingBook.type = data['type'] ?? existingBook.type;
  //         existingBook.chapter = data['chapter'] ?? existingBook.chapter;
  //         existingBook.imageUrl = data['imageUrl'] ?? existingBook.imageUrl;
  //         existingBook.linkURL = data['linkURL'] ?? existingBook.linkURL;
  //         if (lastRead != null && (existingBook.lastRead == null ||
  //             lastRead.isAfter(existingBook.lastRead!))) {
  //           existingBook.lastRead = lastRead;
  //         }
  //
  //         await existingBook.save();
  //       } else {
  //         final book = Book(
  //           id: doc.id,
  //           title: data['title'] ?? 'Untitled',
  //           type: data['type'] ?? 'Novel',
  //           chapter: data['chapter'] ?? 1,
  //           imageUrl: data['imageUrl'],
  //           linkURL: data['linkURL'],
  //           uid: data['uid'],
  //           lastRead: lastRead,
  //         );
  //
  //         await bookBox.add(book);
  //       }
  //     }
  //
  //     setState(() {});
  //   } catch (e) {
  //     print("Error fetching books: $e");
  //     _showErrorSnackbar("Failed to load books from cloud.");
  //   }
  // }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSyncSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 1),
      ),
    );
  }
}