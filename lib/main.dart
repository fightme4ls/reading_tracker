import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/main_screen.dart';
import 'screens/login_page.dart';
import 'models/book.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/theme_provider.dart';

Future<void> updateExistingBooks() async {
  final bookBox = Hive.box<Book>('books');
  final now = DateTime.now();

  for (int i = 0; i < bookBox.length; i++) {
    final book = bookBox.getAt(i);
    if (book != null && book.lastRead == null) {
      book.lastRead = now;
      await book.save();

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

Future<String> _getCurrentAppVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

Future<String?> _getLatestAppVersionFromRemoteConfig() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  try {
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 24),
    ));
    await remoteConfig.fetchAndActivate();
    return remoteConfig.getString('latest_app_version');
  } catch (e) {
    print("Error fetching remote config: $e");
    return null;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: _MyAppContent(),
    );
  }
}

class _MyAppContent extends StatefulWidget {
  @override
  _MyAppContentState createState() => _MyAppContentState();
}

class _MyAppContentState extends State<_MyAppContent> {
  bool _updateAvailable = false;
  bool _checkingForUpdate = true;

  @override
  void initState() {
    super.initState();
    _checkAppVersion();
  }


  Future<void> _checkAppVersion() async {
    final currentVersion = await _getCurrentAppVersion();
    final latestVersion = await _getLatestAppVersionFromRemoteConfig();

    print("Current app version: $currentVersion");
    print("Latest version from Remote Config: $latestVersion");

    if (latestVersion != null) {
      final isNewer = _isNewerVersion(latestVersion, currentVersion);
      print("Is newer version available? $isNewer");

      setState(() {
        _updateAvailable = isNewer;
        _checkingForUpdate = false;
      });
    } else {
      print("Could not retrieve latest version from Remote Config");
      setState(() {
        _checkingForUpdate = false;
      });
    }

    if (!_updateAvailable) {
      _navigateToInitialScreen(context);
    }
  }

  bool _isNewerVersion(String latest, String current) {
    List<int> latestParts = latest.split('.').map((part) {
      return int.tryParse(part) ?? 0;
    }).toList();

    List<int> currentParts = current.split('.').map((part) {
      return int.tryParse(part) ?? 0;
    }).toList();

    int maxLength = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;

    while (latestParts.length < maxLength) {
      latestParts.add(0);
    }

    while (currentParts.length < maxLength) {
      currentParts.add(0);
    }

    for (int i = 0; i < maxLength; i++) {
      if (latestParts[i] > currentParts[i]) {
        return true;
      } else if (latestParts[i] < currentParts[i]) {
        return false;
      }
    }

    return false;
  }

  Future<void> _launchPlayStore() async {
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=edu.cpp.reading_tracker';
    final Uri url = Uri.parse(playStoreUrl);
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  void _navigateToInitialScreen(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => InitialScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (_checkingForUpdate) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_updateAvailable) {
      return MaterialApp(
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
        themeMode: themeProvider.themeMode,
        home: Scaffold(
          body: Center(
            child: Card(
              margin: const EdgeInsets.all(32.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.system_update_rounded,
                      size: 60.0,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'New Update Available!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.headlineSmall?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'To enjoy the latest features and improvements, please update the app now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _updateAvailable = false;
                            });
                            _navigateToInitialScreen(context);
                          },
                          child: const Text('Update Later', style: TextStyle(fontSize: 16)),
                        ),
                        ElevatedButton(
                          onPressed: _launchPlayStore,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                          ),
                          child: const Text('Update Now', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return MaterialApp(
        title: 'Reading Tracker',
        theme: ThemeData(primarySwatch: Colors.blue),
        darkTheme: ThemeData.dark(),
        themeMode: themeProvider.themeMode,
        home: InitialScreen(),
      );
    }
  }
}

class InitialScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      return MainScreen();
    } else {
      return LoginPage();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseRemoteConfig.instance.setDefaults(<String, dynamic>{
    'latest_app_version': '1.0.0',
  });
  await Hive.initFlutter();
  Hive.registerAdapter(BookAdapter());
  await Hive.openBox<Book>('books');
  await updateExistingBooks();
  runApp(MyApp());
}