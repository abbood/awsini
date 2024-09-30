import 'package:awsini/services/cached_url_fetcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:math';

import 'firebase_options.dart';
import 'widgets/wallpaper_detail_page.dart';

void main() async {
  print("Starting app initialization");
  WidgetsFlutterBinding.ensureInitialized();
  print("Flutter binding initialized");
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
  await CachedUrlFetcher.loadCache();
  print("Running app");
  runApp(WallpaperMarketplaceApp());
}

class WallpaperMarketplaceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wallpaper Marketplace',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WallpaperGallery(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WallpaperGallery extends StatefulWidget {
  @override
  _WallpaperGalleryState createState() => _WallpaperGalleryState();
}

class _WallpaperGalleryState extends State<WallpaperGallery> {
  List<Map<String, dynamic>> wallpapers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchWallpapers();
  }

  Future<void> fetchWallpapers() async {
    for (int i = 0; i < 10; i++) {
      wallpapers.add({
        'id': BoneMock.name,
        'thumbnail_file': BoneMock.chars(30),
        'vector_file': BoneMock.chars(30),
        'detail_file': BoneMock.chars(30),
        'translation': BoneMock.chars(30),
      });
    }

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final QuerySnapshot snapshot =
          await firestore.collection('wallpapers').get();

      // Check if data is newer than our last fetch
      final prefs = await SharedPreferences.getInstance();
      final lastFetch = prefs.getInt('last_wallpaper_fetch') ?? 0;

      int newestTimestamp = lastFetch;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'];
        if (timestamp is int && timestamp > newestTimestamp) {
          newestTimestamp = timestamp;
        }
      }

      if (newestTimestamp > lastFetch) {
        // New data available, clear cache
        await CachedUrlFetcher.clearCache();
        await prefs.setInt('last_wallpaper_fetch', newestTimestamp);
      }

      List<Map<String, dynamic>> fetchedWallpapers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String thumbnailUrl =
            await CachedUrlFetcher.getImageUrl(data['thumbnail_file'] ?? '');
        String vectorUrl =
            await CachedUrlFetcher.getImageUrl(data['vector_file'] ?? '');
        String detailUrl =
            await CachedUrlFetcher.getImageUrl(data['detail_file'] ?? '');

        fetchedWallpapers.add({
          'id': data['id'] ?? '',
          'thumbnail_file': thumbnailUrl,
          'vector_file': vectorUrl,
          'detail_file': detailUrl,
          'translation': data['translation'] ?? '',
        });
      }

      setState(() {
        wallpapers = fetchedWallpapers;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching wallpapers: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> getImageUrl(String imagePath) async {
    try {
      final ref = FirebaseStorage.instance.ref().child('$imagePath');
      print('Attempting to fetch URL for: $imagePath');
      String downloadURL = await ref.getDownloadURL();
      print('Successfully fetched URL: $downloadURL');
      return downloadURL;
    } catch (e) {
      print('Error fetching image URL for $imagePath: $e');
      return ''; // Return an empty string or a placeholder image URL
    }
  }

  List<String> _generateRandomChips() {
    List<String> possibleContents = [
      'New',
      'Hot',
      'Trending',
      'Popular',
      'Featured'
    ];
    possibleContents.shuffle();
    return possibleContents.take(Random().nextInt(2) + 1).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Skeletonizer(
              enabled: isLoading,
              child: GridView.builder(
                padding: EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 9 / 16,
                ),
                itemCount: wallpapers.length,
                itemBuilder: (context, index) {
                  List<String> chipContents = _generateRandomChips();
                  
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WallpaperDetailPage(
                            pngUrl: wallpapers[index]['thumbnail_file'],
                            svgUrl: wallpapers[index]['vector_file'],
                            detailUrl: wallpapers[index]['detail_file'],
                            translationText: wallpapers[index]['translation'],
                          ),
                        ),
                      );
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Skeleton.replace(
                            child: CachedNetworkImage(
                              imageUrl: wallpapers[index]['thumbnail_file'],
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Icon(Icons.error),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: chipContents.map((content) => Padding(
                              padding: EdgeInsets.only(bottom: 4),
                              child: Chip(
                                label: Text(
                                  content,
                                  style: TextStyle(fontSize: 10, color: Colors.white),
                                ),
                                backgroundColor: Colors.black.withOpacity(0.7),
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (isLoading)
              Center(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Fetching your wallpapers,\nthis will take a few seconds...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
