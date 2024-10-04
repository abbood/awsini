import 'package:awsini/services/cached_url_fetcher.dart';
import 'package:awsini/widgets/wallpaper_grid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  List<Map<String, dynamic>> favoriteWallpapers = [];
  bool isLoading = true;
  Set<String> favorites = {};

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      favorites = Set<String>.from(prefs.getStringList('favorites') ?? []);
    });
    fetchFavoriteWallpapers();
  }

  Future<void> fetchFavoriteWallpapers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final QuerySnapshot snapshot = await firestore
          .collection('wallpapers')
          .where('id', whereIn: favorites.toList())
          .get();

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
          'ar': data['ar'] ?? '',
          'tags': data['tags'] ?? '',
        });
      }

      setState(() {
        favoriteWallpapers = fetchedWallpapers;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching favorite wallpapers: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void toggleFavorite(String id) async {
    setState(() {
      if (favorites.contains(id)) {
        favorites.remove(id);
        favoriteWallpapers.removeWhere((wallpaper) => wallpaper['id'] == id);
      } else {
        favorites.add(id);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', favorites.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
      ),
      body: WallpaperGrid(
        wallpapers: favoriteWallpapers,
        toggleFavorite: toggleFavorite,
        favorites: favorites,
        isLoading: isLoading,
      ),
    );
  }
}
