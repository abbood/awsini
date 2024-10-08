import 'package:awsini/services/cached_url_fetcher.dart';
import 'package:awsini/widgets/wallpaper_grid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ExplorePage extends StatefulWidget {
  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<Map<String, dynamic>> wallpapers = [];
  bool isLoading = true;
  Set<String> favorites = {};

  @override
  void initState() {
    super.initState();
    fetchWallpapers();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = Set<String>.from(prefs.getStringList('favorites') ?? []);
    });
  }

  Future<void> saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites.toList());
  }

  void toggleFavorite(String id) {
    setState(() {
      if (favorites.contains(id)) {
        favorites.remove(id);
      } else {
        favorites.add(id);
      }
    });
    saveFavorites();
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

        fetchedWallpapers.add({
          'id': data['id'] ?? '',
          'thumbnail_file': thumbnailUrl,
          'vector_file': data['vector_file'] ?? '',
          'detail_file': data['detail_file'] ?? '',
          'translation': data['translation'] ?? '',
          'artist_id': data['artist_id'] ?? null,
          'ar': data['ar'] ?? '',
          'tags': data['tags'] ?? '',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WallpaperGrid(
              showSearchBar: true,
              wallpapers: wallpapers,
              toggleFavorite: toggleFavorite,
              favorites: favorites,
              isLoading: isLoading,
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
