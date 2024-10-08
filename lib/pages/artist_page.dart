import 'package:awsini/services/cached_url_fetcher.dart';
import 'package:awsini/widgets/artist_info_card.dart';
import 'package:awsini/widgets/wallpaper_grid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ArtistPage extends StatefulWidget {
  final String artistId;

  const ArtistPage({Key? key, required this.artistId}) : super(key: key);

  @override
  _ArtistPageState createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  late Future<Map<String, dynamic>> _artistDataFuture;
  late Future<List<Map<String, dynamic>>> _wallpapersFuture;

  @override
  void initState() {
    super.initState();
    _artistDataFuture = _fetchArtistData();
    _wallpapersFuture = _fetchArtistWallpapers();
  }

  Future<Map<String, dynamic>> _fetchArtistData() async {
    final artistDoc = await FirebaseFirestore.instance
        .collection('artists')
        .doc(widget.artistId)
        .get();

    if (artistDoc.exists) {
      final data = artistDoc.data() as Map<String, dynamic>;
      final pictureUrl = await CachedUrlFetcher.getImageUrl(
          data['picture_url'] ?? '',
          folder: 'artists');
      final signatureUrl = await CachedUrlFetcher.getImageUrl(
          data['signature_url'] ?? '',
          folder: 'artists');

      return {
        ...data,
        'picture_url': pictureUrl,
        'signature_url': signatureUrl,
      };
    } else {
      throw Exception('Artist not found');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchArtistWallpapers() async {
    final wallpaperSnapshot = await FirebaseFirestore.instance
        .collection('wallpapers')
        .where('artist_id', isEqualTo: widget.artistId)
        .get();

    return Future.wait(wallpaperSnapshot.docs.map((doc) async {
      final data = doc.data();
      final thumbnailUrl =
          await CachedUrlFetcher.getImageUrl(data['thumbnail_file'] ?? '');
      return {
        ...data,
        'id': doc.id,
        'thumbnail_file': thumbnailUrl,
      };
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Artist Wallpapers'),
      ),
      body: Column(
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _artistDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error loading artist data'));
              } else if (!snapshot.hasData) {
                return Center(child: Text('Artist not found'));
              } else {
                return ArtistInfoCard(
                  artistData: snapshot.data!,
                  // We don't need onViewWallpapers here since we're already on the artist's page
                );
              }
            },
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _wallpapersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading wallpapers'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No wallpapers available'));
                } else {
                  return WallpaperGrid(
                    wallpapers: snapshot.data!,
                    // We're not handling favorites on this page, so we don't pass toggleFavorite and favorites
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
