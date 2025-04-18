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
      // Optionally show an error message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load random manga.')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRandomManga(); // Fetch initial random manga when the screen loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore Manga'),
        centerTitle: true,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildWarningText(),
            SizedBox(height: 24),
            _buildRandomButton(),
            SizedBox(height: 24),
            if (randomMangaTitle != null) _buildMangaCard(),
            if (randomMangaTitle == null) _buildLoadingIndicator(), // Show loading indicator initially
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showGenreFilter(context),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Icon(Icons.filter_list),
        tooltip: 'Filter by Genre',
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildLoadingIndicator() {
    return CircularProgressIndicator(color: Colors.blueAccent);
  }

  Widget _buildWarningText() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Experimental feature. May experience lag and longer wait times.',
              style: TextStyle(color: Colors.amber.shade900, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRandomButton() {
    return ElevatedButton.icon(
      onPressed: fetchRandomManga,
      icon: Icon(Icons.shuffle, color: Colors.white),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        child: Text('Pick a Random Manga', style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (randomMangaImage != null && randomMangaImage!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                randomMangaImage!,
                height: 220,
                fit: BoxFit.contain, // Changed BoxFit.cover to BoxFit.contain
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    color: Colors.grey.shade300,
                    child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey.shade600)),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              randomMangaTitle ?? 'No Title',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
        label: Text(genre, style: TextStyle(color: Colors.blue.shade900)),
        backgroundColor: Colors.blue.shade100,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
          style: TextStyle(fontSize: 16, color: Colors.black87),
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
              color: Colors.blueAccent,
            ),
            label: Text(isSynopsisExpanded ? 'Show Less' : 'Show More', style: TextStyle(color: Colors.blueAccent)),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Filter by Genres",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: availableGenres.map((genre) {
                      final isSelected = selectedGenres.contains(genre);
                      return ChoiceChip(
                        label: Text(genre, style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        )),
                        selected: isSelected,
                        selectedColor: Colors.blueAccent,
                        backgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedGenres.clear();
                          });
                          Navigator.pop(context);
                        },
                        child: Text("Clear All", style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          fetchRandomManga(); // Re-fetch with applied filters
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          textStyle: TextStyle(fontSize: 16),
                        ),
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