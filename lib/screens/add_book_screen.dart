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

  String selectedType = 'Novel';
  List<dynamic> searchResults = [];
  String? selectedImage;
  String? selectedTitle;

  bool _isManualEntry = false;

  final String _placeholderImage =
      'https://placehold.co/600x400/png/?text=Manual\nEntry&font=Oswald'; // Placeholder image URL

  Future<void> _searchManga(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    final response = await http.get(Uri.parse('https://api.jikan.moe/v4/manga?q=$query&limit=5'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        searchResults = data['data'];
      });
    } else {
      throw Exception('Failed to load search results');
    }
  }

  void _onSelectManga(dynamic manga) {
    setState(() {
      selectedTitle = manga['title'];
      selectedImage = manga['images']['jpg']['image_url'];
      titleController.text = selectedTitle!;
      searchResults = [];
    });
  }

  void _addBook() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to add a book!'), duration: Duration(seconds: 2)),
      );
      return;
    }

    final title = titleController.text;
    final chapter = int.tryParse(chapterController.text) ?? 1;
    final uid = user.uid;

    if (title.isNotEmpty) {
      final book = Book(
        title: title,
        type: selectedType,
        chapter: chapter,
        imageUrl: selectedImage ?? _placeholderImage,
        uid: uid,
      );

      final box = Hive.box<Book>('books');
      await box.add(book);

      FirebaseFirestore.instance.collection("books").add({
        "title": title,
        "type": selectedType,
        "chapter": chapter,
        "imageUrl": selectedImage ?? _placeholderImage,
        "linkURL": '',
        "uid": uid
      }).then((docRef) {
        book.id = docRef.id;
        book.save();
        print("Book added with Firestore ID: ${docRef.id}");
      }).catchError((error) {
        print("Book not added to Firestore!");
        print(error.toString());
      });

      widget.onBookAdded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //title: Text("Add Book"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isManualEntry = !_isManualEntry;
                searchResults = [];
                selectedImage = null;
              });
            },
            child: Text(
              _isManualEntry ? "Use Search" : "Manual Entry",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title input
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.book),
              ),
              onChanged: (value) {
                if (!_isManualEntry) _searchManga(value);
              },
            ),

            // Search results (only if not manual mode)
            if (!_isManualEntry && searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final manga = searchResults[index];
                    return ListTile(
                      leading: Image.network(
                        manga['images']['jpg']['image_url'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                      title: Text(manga['title']),
                      subtitle: Text(manga['type']),
                      onTap: () => _onSelectManga(manga),
                    );
                  },
                ),
              ),

            // Show selected image or placeholder
            if (selectedImage != null || _isManualEntry)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network(
                  selectedImage ?? _placeholderImage,
                  height: 150,
                ),
              ),

            // Type dropdown
            DropdownButton<String>(
              value: selectedType,
              items: ['Novel', 'Manga', 'Manhwa', 'Light Novel'].map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (value) => setState(() => selectedType = value!),
            ),

            // Chapter input
            TextField(
              controller: chapterController,
              decoration: InputDecoration(labelText: 'Chapter'),
              keyboardType: TextInputType.number,
            ),

            SizedBox(height: 20),
            ElevatedButton(onPressed: _addBook, child: Text('Add')),
          ],
        ),
      ),
    );
  }
}

