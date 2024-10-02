import 'package:awsini/pages/wallpaper_detail_page.dart';
import 'package:awsini/services/cached_url_fetcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : favoriteWallpapers.isEmpty
              ? Center(child: Text('No favorites yet'))
              : GridView.builder(
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 9 / 16,
                  ),
                  itemCount: favoriteWallpapers.length,
                  itemBuilder: (context, index) {
                    List<String> tags = [];
                    if (favoriteWallpapers[index]['tags'] != null) {
                      tags = (favoriteWallpapers[index]['tags'] as String)
                          .split(',')
                          .map((tag) => tag.trim())
                          .where((tag) => tag.isNotEmpty)
                          .toList();
                    }

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WallpaperDetailPage(
                                thumbnailUrl: favoriteWallpapers[index]
                                    ['thumbnail_file'],
                                rawVectorUrl: favoriteWallpapers[index]
                                    ['vector_file'],
                                rawDetailUrl: favoriteWallpapers[index]
                                    ['detail_file'],
                                translationText: favoriteWallpapers[index]
                                    ['translation'],
                                arabicText: favoriteWallpapers[index]['ar'],
                                tags: tags),
                          ),
                        );
                      },
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: favoriteWallpapers[index]
                                  ['thumbnail_file'],
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.error),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: tags
                                  .map((tag) => Padding(
                                        padding: EdgeInsets.only(bottom: 4),
                                        child: Chip(
                                          label: Text(
                                            tag,
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.white),
                                          ),
                                          backgroundColor:
                                              Colors.black.withOpacity(0.7),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 0),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => toggleFavorite(
                                  favoriteWallpapers[index]['id']),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.favorite,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
