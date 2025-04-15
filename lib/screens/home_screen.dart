import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? randomMangaTitle;
  String? randomMangaImage;
  String? randomMangaSynopsis;
  String? randomMangaUrl;
  List<String> randomMangaGenres = [];
  bool isSynopsisExpanded = false;
  Set<String> selectedGenres = {}; // Store selected genres for filtering

  final List<String> availableGenres = [
    "Action",
    "Adventure",
    "Boys Love",
    "Comedy",
    "Drama",
    "Ecchi",
    "Fantasy",
    "Girls Love",
    "Horror",
    "Romance",
    "Sci-Fi",
    "Slice of Life",
  ];

// Fetch a random manga
  Future<void> fetchRandomManga() async {
    final url = Uri.parse('https://api.jikan.moe/v4/random/manga');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final manga = data['data'];

        List<String> genres = List<String>.from(manga['genres'].map((genre) => genre['name']));

        // Check if the manga contains the "Hentai" genre and retry if it does
        if (genres.contains("Hentai") || genres.contains("Erotica")) {
          print("Hentai/Erotica manga detected. Retrying...");
          fetchRandomManga();
          return;
        }

        // Check if the manga matches selected genres
        if (selectedGenres.isEmpty || genres.any((g) => selectedGenres.contains(g))) {
          setState(() {
            randomMangaTitle = manga['title'];
            randomMangaImage = manga['images']['jpg']['image_url'];
            randomMangaSynopsis = manga['synopsis'];
            randomMangaUrl = manga['url'];
            randomMangaGenres = genres;
          });
        } else {
          // If the fetched manga doesn't match, fetch again
          print("Genres incorrect. Retrying...");
          fetchRandomManga();
        }
      } else {
        throw Exception('Failed to load random manga');
      }
    } catch (error) {
      print('Error fetching random manga: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: Text('Random Manga Picker'),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.account_circle),
        //     onPressed: () {
        //       Navigator.pushReplacement(
        //         context,
        //         MaterialPageRoute(builder: (context) => AccountScreen()),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
          children: [
            Text('Extremely Experimental. Expect Lag And Long Waits.'),
            SizedBox(height: 20),
            Center( // Center the button
              child: ElevatedButton(
                onPressed: fetchRandomManga,
                child: Text('Pick a Random Manga'),
              ),
            ),
            SizedBox(height: 20),
            if (randomMangaTitle != null)
              Center( // Center the card
                child: Card(
                  elevation: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center, // Center text inside the card
                    children: [
                      if (randomMangaImage != null && randomMangaImage!.isNotEmpty)
                        Image.network(randomMangaImage!, height: 150, fit: BoxFit.cover),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(randomMangaTitle ?? 'No Title',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildGenres(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildSynopsis(),
                      ),
                      if (randomMangaUrl != null)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton(
                            onPressed: () {
                              if (randomMangaUrl != null) {
                                _launchURL(randomMangaUrl!);
                              }
                            },
                            child: Text('Read more on MyAnimeList'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGenreFilter(context),
        child: Icon(Icons.filter_list),
        tooltip: 'Filter by Genre',
      ),
    );
  }

  // Genre filtering modal
  void _showGenreFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Select Genres", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: availableGenres.map((genre) {
                      final isSelected = selectedGenres.contains(genre);
                      return ChoiceChip(
                        label: Text(genre),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            setState(() {
                              if (selected) {
                                selectedGenres.add(genre);
                              } else {
                                selectedGenres.remove(genre);
                              }
                              print("Selected Genres: $selectedGenres"); // Debugging output
                            });
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Apply Filter"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Build genre chips
  Widget _buildGenres() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: randomMangaGenres
          .map((genre) => Chip(
        label: Text(genre),
        backgroundColor: Colors.grey,
      ))
          .toList(),
    );
  }

  // Build synopsis with expand/collapse
  Widget _buildSynopsis() {
    final synopsis = randomMangaSynopsis ?? 'No synopsis available';
    const int maxLength = 150;

    final truncatedSynopsis = synopsis.length > maxLength
        ? synopsis.substring(0, maxLength) + '...'
        : synopsis;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSynopsisExpanded ? synopsis : truncatedSynopsis,
          style: TextStyle(fontSize: 14),
        ),
        if (synopsis.length > maxLength)
          TextButton(
            onPressed: () {
              setState(() {
                isSynopsisExpanded = !isSynopsisExpanded;
              });
            },
            child: Text(isSynopsisExpanded ? 'Show Less' : 'Show More'),
          ),
      ],
    );
  }

  // Open manga URL
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
