import 'package:awsini/helpers/wallpaper_helpers.dart';
import 'package:awsini/models/wallpaper.dart';
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
  List<Wallpaper> favoriteWallpapers = [];
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

      List<Wallpaper> fetchedWallpapers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String thumbnailUrl =
            await CachedUrlFetcher.getImageUrl(data['thumbnail_file'] ?? '');

        List<String> tags;
        if (data['tags'] is String) {
          tags = (data['tags'] as String).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        } else if (data['tags'] is List) {
          tags = List<String>.from(data['tags']);
        } else {
          tags = [];
        }

        fetchedWallpapers.add(Wallpaper(
          id: doc.id,
          thumbnailFile: thumbnailUrl,
          vectorFile: data['vector_file'] ?? '',
          detailFile: data['detail_file'] ?? '',
          translation: data['translation'] ?? '',
          artistId: data['artist_id'],
          ar: data['ar'] ?? '',
          tags: tags, 
          variations: WallpaperHelpers.parseVariations(data['variations']),
        ));
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
        favoriteWallpapers.removeWhere((wallpaper) => wallpaper.id == id);
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
