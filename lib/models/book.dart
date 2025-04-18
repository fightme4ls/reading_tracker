import 'package:hive/hive.dart';

part 'book.g.dart';

@HiveType(typeId: 0)
class Book extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String type; // Novel, Manga, Manhwa, etc.

  @HiveField(2)
  int chapter;

  @HiveField(3)
  String? imageUrl; // Store the image URL

  @HiveField(4)
  String? linkURL;

  @HiveField(5)
  String? id; // Firestore Document ID (for syncing with Firestore)

  @HiveField(6)
  String? uid; // UID of the user who added the book (for linking to specific user)

  @HiveField(7)
  DateTime? lastRead; // Timestamp of when the book was last read

  Book({
    required this.title,
    required this.type,
    required this.chapter,
    this.imageUrl,
    this.linkURL,
    this.id,
    this.uid,
    this.lastRead,
  });
}