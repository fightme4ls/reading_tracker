import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/book.dart';

class BookSyncService {
  static final BookSyncService _instance = BookSyncService._internal();

  factory BookSyncService() {
    return _instance;
  }

  BookSyncService._internal();

  DateTime? _lastSyncTime;

  final Duration _minSyncInterval = Duration(seconds: 30);

  VoidCallback? onSyncComplete;

  bool get canSync => _lastSyncTime == null ||
      DateTime.now().difference(_lastSyncTime!) > _minSyncInterval;

  Future<bool> syncBooksFromFirestore({bool forceSync = false}) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final userId = user.uid;
    final bookBox = Hive.box<Book>('books');

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('uid', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        DateTime? lastRead;
        if (data['lastRead'] != null) {
          try {
            lastRead = DateTime.parse(data['lastRead']);
          } catch (e) {
            print("Error parsing lastRead date: $e");
          }
        }

        final existingBookIndex =
        bookBox.values.toList().indexWhere((b) => b.id == doc.id);

        if (existingBookIndex != -1) {
          final existingBook = bookBox.getAt(existingBookIndex)!;
          existingBook.title = data['title'] ?? existingBook.title;
          existingBook.type = data['type'] ?? existingBook.type;
          existingBook.chapter = data['chapter'] ?? existingBook.chapter;
          existingBook.imageUrl = data['imageUrl'] ?? existingBook.imageUrl;
          existingBook.linkURL = data['linkURL'] ?? existingBook.linkURL;

          if (lastRead != null &&
              (existingBook.lastRead == null ||
                  lastRead.isAfter(existingBook.lastRead!))) {
            existingBook.lastRead = lastRead;
          }

          await existingBook.save();
        } else {
          final book = Book(
            id: doc.id,
            title: data['title'] ?? 'Untitled',
            type: data['type'] ?? 'Novel',
            chapter: data['chapter'] ?? 1,
            imageUrl: data['imageUrl'],
            linkURL: data['linkURL'],
            uid: data['uid'],
            lastRead: lastRead,
          );

          await bookBox.add(book);
        }
      }

      final firestoreBookIds = snapshot.docs.map((doc) => doc.id).toSet();
      final localBooks =
      bookBox.values.where((book) => book.uid == userId).toList();

      for (var localBook in localBooks) {
        if (localBook.id != null && !firestoreBookIds.contains(localBook.id)) {
          // If book exists locally but not in Firestore
          // delete locally too
          await localBook.delete();
          print("Book ${localBook.title} deleted locally");

          //Debug logging
          //print("Book ${localBook.title} exists locally but not in Firestore");
        }
      }

      _lastSyncTime = DateTime.now();

      onSyncComplete?.call();

      return true;
    } catch (e) {
      print("Error fetching books: $e");
      return false;
    }
  }
}