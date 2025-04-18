import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? randomMangaTitle;
  String? randomMangaImage;
  String? randomMangaSynopsis;
  List<String> randomMangaGenres = [];
  bool isSynopsisExpanded = false;
  Set<String> selectedGenres = {};

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

  Future<void> fetchRandomManga() async {
    final url = Uri.parse('https://api.jikan.moe/v4/random/manga');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final manga = data['data'];

        List<String> genres = List<String>.from(manga['genres'].map((genre) => genre['name']));

        if (genres.contains("Hentai") || genres.contains("Erotica")) {
          print("Hentai/Erotica manga detected. Retrying...");
          fetchRandomManga();
          return;
        }

        if (selectedGenres.isEmpty || genres.any((g) => selectedGenres.contains(g))) {
          setState(() {
            randomMangaTitle = manga['title'];
            randomMangaImage = manga['images']['jpg']['image_url'];
            randomMangaSynopsis = manga['synopsis'];
            randomMangaGenres = genres;
            isSynopsisExpanded = false;
          });
        } else {
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
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildWarningText(),
            SizedBox(height: 24),
            _buildRandomButton(),
            SizedBox(height: 24),
            if (randomMangaTitle != null) _buildMangaCard(),
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

  Widget _buildWarningText() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade900),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Experimental feature. May experience lag and longer wait times.',
              style: TextStyle(color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRandomButton() {
    return ElevatedButton.icon(
      onPressed: fetchRandomManga,
      icon: Icon(Icons.shuffle),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Text('Pick a Random Manga', style: TextStyle(fontSize: 16)),
      ),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildMangaCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (randomMangaImage != null && randomMangaImage!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                randomMangaImage!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              randomMangaTitle ?? 'No Title',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildGenres(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSynopsis(),
          ),
        ],
      ),
    );
  }

  Widget _buildGenres() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      alignment: WrapAlignment.center,
      children: randomMangaGenres
          .map((genre) => Chip(
        label: Text(genre),
        backgroundColor: Colors.blue.shade100,
        labelStyle: TextStyle(color: Colors.blue.shade900),
      ))
          .toList(),
    );
  }

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
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.justify,
        ),
        if (synopsis.length > maxLength)
          TextButton.icon(
            onPressed: () {
              setState(() {
                isSynopsisExpanded = !isSynopsisExpanded;
              });
            },
            icon: Icon(
              isSynopsisExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),
            label: Text(isSynopsisExpanded ? 'Show Less' : 'Show More'),
          ),
      ],
    );
  }

  void _showGenreFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Filter by Genres",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: availableGenres.map((genre) {
                      final isSelected = selectedGenres.contains(genre);
                      return ChoiceChip(
                        label: Text(genre),
                        selected: isSelected,
                        selectedColor: Colors.blue.shade100,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.blue.shade900 : Colors.black87,
                        ),
                        onSelected: (selected) {
                          setModalState(() {
                            setState(() {
                              if (selected) {
                                selectedGenres.add(genre);
                              } else {
                                selectedGenres.remove(genre);
                              }
                            });
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            selectedGenres.clear();
                          });
                          Navigator.pop(context);
                        },
                        child: Text("Clear All"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text("Apply Filter"),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
