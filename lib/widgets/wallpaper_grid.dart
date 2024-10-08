import 'package:awsini/pages/wallpaper_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class WallpaperGrid extends StatefulWidget {
  final List<Map<String, dynamic>> wallpapers;
  final Function(String)? toggleFavorite;
  final Set<String>? favorites;
  final bool isLoading;
  final bool showSearchBar;

  const WallpaperGrid({
    Key? key,
    required this.wallpapers,
    this.toggleFavorite,
    this.favorites,
    this.isLoading = false,
    this.showSearchBar = false,
  }) : super(key: key);

  @override
  _WallpaperGridState createState() => _WallpaperGridState();
}

class _WallpaperGridState extends State<WallpaperGrid> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _filteredWallpapers = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredWallpapers = widget.wallpapers;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void didUpdateWidget(WallpaperGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.wallpapers != oldWidget.wallpapers) {
      _filteredWallpapers = widget.wallpapers;
      _onSearchChanged();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final searchText = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = searchText.length >= 3;
      if (_isSearching) {
        _filteredWallpapers = widget.wallpapers.where((wallpaper) {
          final ar = wallpaper['ar'].toString().toLowerCase();
          final translation = wallpaper['translation'].toString().toLowerCase();
          final tags = (wallpaper['tags'] as String?)
                  ?.split(',')
                  .map((tag) => tag.trim().toLowerCase())
                  .where((tag) => tag.isNotEmpty)
                  .toList() ??
              [];

          return ar.contains(searchText) ||
              translation.contains(searchText) ||
              tags.any((tag) => tag.contains(searchText));
        }).toList();
      } else {
        _filteredWallpapers = widget.wallpapers;
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _filteredWallpapers = widget.wallpapers;
      _isSearching = false;
    });
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollStartNotification) {
          _searchFocusNode.unfocus();
        }
        return true;
      },
      child: Skeletonizer(
        enabled: widget.isLoading,
        child: CustomScrollView(
          slivers: [
            if (widget.showSearchBar)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Search wallpapers...',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.all(8),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 9 / 16,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final wallpaper = _filteredWallpapers[index];
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
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                              ),
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
                                  .map((tag) => _buildTagChip(tag))
                                  .toList(),
                            ),
                          ),
                          if (widget.toggleFavorite != null &&
                              widget.favorites != null)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () =>
                                    widget.toggleFavorite!(wallpaper['id']),
                                child: _buildFavoriteIcon(wallpaper['id']),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  childCount: _filteredWallpapers.length,
                ),
              ),
            ),
          ],
        ),
      ),
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
        widget.favorites!.contains(id) ? Icons.favorite : Icons.favorite_border,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
