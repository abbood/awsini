import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:awsini/pages/wallpaper_detail_page.dart';

class WallpaperGrid extends StatelessWidget {
  final List<Map<String, dynamic>> wallpapers;
  final Function(String) toggleFavorite;
  final Set<String> favorites;
  final bool isLoading;

  const WallpaperGrid({
    Key? key,
    required this.wallpapers,
    required this.toggleFavorite,
    required this.favorites,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (wallpapers.isEmpty) {
      return Center(child: Text('No wallpapers available'));
    }

    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 9 / 16,
      ),
      itemCount: wallpapers.length,
      itemBuilder: (context, index) {
        final wallpaper = wallpapers[index];
        final List<String> tags = (wallpaper['tags'] as String?)
                ?.split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList() ??
            [];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WallpaperDetailPage(
                  rawVectorUrl: wallpaper['vector_file'],
                  rawDetailUrl: wallpaper['detail_file'],
                  translationText: wallpaper['translation'],
                  arabicText: wallpaper['ar'],
                  tags: tags,
                  artistId: wallpaper['artist_id'],
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: wallpaper['thumbnail_file'],
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: tags.map((tag) => _buildTagChip(tag)).toList(),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => toggleFavorite(wallpaper['id']),
                  child: _buildFavoriteIcon(wallpaper['id']),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagChip(String tag) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Chip(
        label: Text(
          tag,
          style: TextStyle(fontSize: 10, color: Colors.white),
        ),
        backgroundColor: Colors.black.withOpacity(0.7),
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Widget _buildFavoriteIcon(String id) {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        favorites.contains(id) ? Icons.favorite : Icons.favorite_border,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
