import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../models/book.dart';

class AddBookScreen extends StatefulWidget {
  final Function onBookAdded;

  AddBookScreen({required this.onBookAdded});

  @override
  _AddBookScreenState createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController chapterController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  String selectedType = 'Novel';
  List<dynamic> searchResults = [];
  String? selectedImage;
  String? selectedTitle;
  bool _isManualEntry = false;
  bool _isLoading = false;

  final List<String> bookTypes = ['Novel', 'Manga', 'Manhwa', 'Light Novel'];
  final String _placeholderImage = 'https://placehold.co/600x400/png/?text=Manual\nEntry&font=Oswald';

  @override
  void initState() {
    super.initState();
    chapterController.text = '1';
  }

  @override
  void dispose() {
    titleController.dispose();
    chapterController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isManualEntry ? 'Manual Entry' : 'Search & Add'),
        actions: [
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isManualEntry = !_isManualEntry;
                searchResults = [];
                selectedImage = null;
                if (!_isManualEntry) {
                  imageUrlController.clear();
                }
              });
            },
            icon: Icon(_isManualEntry ? Icons.search : Icons.edit),
            label: Text(_isManualEntry ? "Use Search" : "Manual Entry"),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isLoading) ...[
              LinearProgressIndicator(),
              SizedBox(height: 16),
            ],
            _buildEntryForm(),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTitleField(),
        SizedBox(height: 20),
        if (!_isManualEntry && searchResults.isNotEmpty)
          _buildSearchResults(),
        if (selectedImage != null || _isManualEntry)
          _buildImagePreview(),
        SizedBox(height: 20),
        _buildTypeDropdown(),
        SizedBox(height: 20),
        _buildChapterField(),
        if (_isManualEntry) ...[
          SizedBox(height: 20),
          _buildImageUrlField(),
        ],
        SizedBox(height: 32),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: titleController,
      decoration: InputDecoration(
        labelText: 'Title',
        hintText: 'Enter book title',
        prefixIcon: Icon(Icons.book),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (value) {
        if (!_isManualEntry) {
          _searchManga(value); // Trigger search on every text change
        }
      },
    );
  }

  Widget _buildSearchResults() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        itemCount: searchResults.length,
        separatorBuilder: (context, index) => Divider(height: 1),
        itemBuilder: (context, index) {
          final manga = searchResults[index];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                manga['images']['jpg']['image_url'] ?? '',
                width: 50,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 70,
                    color: Colors.grey.shade300,
                    child: Icon(Icons.broken_image),
                  );
                },
              ),
            ),
            title: Text(
              manga['title'] ?? 'Unknown Title',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              manga['type'] ?? 'Unknown Type',
              style: TextStyle(fontSize: 12),
            ),
            onTap: () => _onSelectManga(manga),
          );
        },
      ),
    );
  }

  Widget _buildImagePreview() {
    final imageUrl = _isManualEntry
        ? (imageUrlController.text.isNotEmpty ? imageUrlController.text : _placeholderImage)
        : selectedImage ?? _placeholderImage;

    return Center(
      child: Column(
        children: [
          Container(
            height: 200,
            width: 150,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade200,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Invalid image URL', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8),
          Text('Cover Image', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Content Type',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedType,
          icon: Icon(Icons.arrow_drop_down),
          isExpanded: true,
          items: bookTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  _getTypeIcon(type),
                  SizedBox(width: 8),
                  Text(type),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => selectedType = value!),
        ),
      ),
    );
  }

  Widget _getTypeIcon(String type) {
    switch (type) {
      case 'Novel':
        return Icon(Icons.auto_stories, color: Colors.blue);
      case 'Manga':
        return Icon(Icons.photo_album, color: Colors.red);
      case 'Manhwa':
        return Icon(Icons.web_stories, color: Colors.purple);
      case 'Light Novel':
        return Icon(Icons.menu_book, color: Colors.amber.shade800);
      default:
        return Icon(Icons.book);
    }
  }

  Widget _buildChapterField() {
    return TextField(
      controller: chapterController,
      decoration: InputDecoration(
        labelText: 'Current Chapter',
        hintText: 'Enter current chapter number',
        prefixIcon: Icon(Icons.bookmark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.number,
    );
  }

  Widget _buildImageUrlField() {
    return TextField(
      controller: imageUrlController,
      decoration: InputDecoration(
        labelText: 'Image URL (optional)',
        hintText: 'Enter cover image URL',
        prefixIcon: Icon(Icons.image),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (value) {
        setState(() {});
      },
    );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: _addBook,
      icon: Icon(Icons.add),
      label: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text('Add to Library', style: TextStyle(fontSize: 16)),
      ),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _searchManga(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://api.jikan.moe/v4/manga?q=$query&limit=5'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          searchResults = data['data'];
        });
      }
    } catch (e) {
      print('Error searching manga: $e');
      _showErrorSnackbar('Error connecting to anime database');
    }
  }

  void _onSelectManga(dynamic manga) {
    setState(() {
      selectedTitle = manga['title'];
      selectedImage = manga['images']['jpg']['image_url'];
      titleController.text = selectedTitle!;
      searchResults = [];

      final type = manga['type'];
      if (type != null) {
        if (type == 'Manga') {
          selectedType = 'Manga';
        } else if (type == 'Novel') {
          selectedType = 'Novel';
        } else if (type == 'Light Novel') {
          selectedType = 'Light Novel';
        } else if (type == 'Manhwa') {
          selectedType = 'Manhwa';
        }
      }
    });
  }

  void _addBook() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      _showErrorSnackbar('Please enter a title');
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showErrorSnackbar('Please log in to add a book');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final chapter = int.tryParse(chapterController.text) ?? 1;
      final uid = user.uid;
      final imageUrl = selectedImage ?? _placeholderImage;

      final book = Book(
        title: title,
        type: selectedType,
        chapter: chapter,
        imageUrl: imageUrl,
        uid: uid,
      );

      final box = Hive.box<Book>('books');
      await box.add(book);

      final docRef = await FirebaseFirestore.instance.collection("books").add({
        "title": title,
        "type": selectedType,
        "chapter": chapter,
        "imageUrl": imageUrl,
        "linkURL": '',
        "uid": uid
      });

      book.id = docRef.id;
      await book.save();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title added to your library'),
          backgroundColor: Colors.green,
        ),
      );

      _resetForm();
      widget.onBookAdded();
    } catch (e) {
      print('Error adding book: $e');
      _showErrorSnackbar('Failed to add book. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    titleController.clear();
    chapterController.text = '1';
    setState(() {
      selectedImage = null;
      selectedTitle = null;
      searchResults = [];
    });
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
