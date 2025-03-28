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

  // Function to search manga using the Jikan API
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

  // Function to handle selection from search results
  void _onSelectManga(dynamic manga) {
    setState(() {
      selectedTitle = manga['title'];
      selectedImage = manga['images']['jpg']['image_url'];
      titleController.text = selectedTitle!;
      searchResults = []; // Clear search results after selecting a manga
    });
  }

  void _addBook() async {
    // Get the current user from FirebaseAuth
    User? user = FirebaseAuth.instance.currentUser;

    // Check if the user is logged in
    if (user == null) {
      // If the user is not logged in, show a message and return to prevent adding the book
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to add a book!'),
          duration: Duration(seconds: 2),
        ),
      );
      return; // Prevent further action if not logged in
    }

    // Continue adding the book if the user is logged in
    final title = titleController.text;
    final chapter = int.tryParse(chapterController.text) ?? 1;

    if (title.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      final uid = user?.uid ?? '';

      final book = Book(
        title: title,
        type: selectedType,
        chapter: chapter,
        imageUrl: selectedImage ?? '',
        uid: uid,
      );

      // Add the book to Hive
      final box = Hive.box<Book>('books');
      await box.add(book);

      // Add the book to Firestore and get the document reference
      FirebaseFirestore.instance.collection("books").add(
        {
          "title": title,
          "type": selectedType,
          "chapter": chapter,
          "imageUrl": selectedImage ?? '',
          "linkURL": '',
          "uid": uid
        },
      ).then((docRef) {
        // Once Firestore document is added, store the document ID in the Hive box
        book.id = docRef.id; // Save the Firestore docRef ID into the book object
        book.save(); // Save the updated book object with the id

        print("Book added with Firestore ID: ${docRef.id}");
      }).catchError((error) {
        print("Book not added to Firestore!");
        print(error.toString());
      });

      widget.onBookAdded(); // Notify MainScreen to switch to Library
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Title input with auto search
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _searchManga(value);
                if (value.isEmpty) {
                  setState(() {
                    selectedImage = null; // Clear image if search is empty
                  });
                }
              },
              onTap: () {
                // Clear search results and image if the user taps again
                if (titleController.text.isEmpty) {
                  setState(() {
                    selectedImage = null;
                    searchResults = [];
                  });
                }
              },
            ),
            // Search results display
            if (searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final manga = searchResults[index];
                    return ListTile(
                      leading: manga['images']['jpg']['image_url'] != null
                          ? Image.network(
                        manga['images']['jpg']['image_url'],
                        width: 50, // Set the size of the image
                        height: 50,
                        fit: BoxFit.cover,
                      )
                          : SizedBox.shrink(),
                      title: Text(manga['title']),
                      subtitle: Text(manga['type']),
                      onTap: () => _onSelectManga(manga),
                    );
                  },
                ),
              ),
            // Selected manga image display
            if (selectedImage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network(selectedImage!),
              ),
            // Dropdown for type
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
