import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/main_screen.dart';
import 'models/book.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Function to update existing books with a lastRead timestamp
Future<void> updateExistingBooks() async {
  final bookBox = Hive.box<Book>('books');
  final now = DateTime.now();

  for (int i = 0; i < bookBox.length; i++) {
    final book = bookBox.getAt(i);
    if (book != null && book.lastRead == null) {
      book.lastRead = now;
      await book.save();

      // Also update in Firestore if needed
      if (book.id != null) {
        FirebaseFirestore.instance.collection("books").doc(book.id).update({
          "lastRead": book.lastRead!.toIso8601String(),
        }).catchError((error) {
          print("Failed to update book in Firestore: $error");
        });
      }
    }
  }
  print("Finished updating existing books with lastRead timestamps.");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  Hive.registerAdapter(BookAdapter()); // register  model adapter
  await Hive.openBox<Book>('books'); // open books
  // Call the updateExistingBooks function after opening the Hive box
  await updateExistingBooks();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reading Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainScreen(),
    );
  }
}