import 'dart:io';
import 'dart:ui' as ui;

import 'package:awsini/helpers/permission_helper.dart';
import 'package:awsini/services/cached_url_fetcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class WallpaperDetailPage extends StatefulWidget {
  final String rawVectorUrl;
  final String rawDetailUrl;
  final String translationText;
  final String arabicText;
  final String? artistId;
  final List<String> tags;

  WallpaperDetailPage({
    required this.rawVectorUrl,
    required this.rawDetailUrl,
    required this.translationText,
    required this.arabicText,
    required this.tags,
    this.artistId,
  });

  @override
  _WallpaperDetailPageState createState() => _WallpaperDetailPageState();
}

class _WallpaperDetailPageState extends State<WallpaperDetailPage> {
  bool _addTranslation = false;
  late Future<String> _detailUrlFuture;
  String? _vectorUrl;
  late Future<String> _svgFuture;
  bool _isDownloading = false;
  Future<Map<String, dynamic>>? _artistDataFuture;

  @override
  void initState() {
    super.initState();
    _detailUrlFuture = CachedUrlFetcher.getImageUrl(widget.rawDetailUrl);
    if (widget.artistId != null) {
      _artistDataFuture = _fetchArtistData();
    }
  }

  Future<Map<String, dynamic>> _fetchArtistData() async {
    try {
      final artistDoc = await FirebaseFirestore.instance
          .collection('artists')
          .doc(widget.artistId)
          .get();

      if (artistDoc.exists) {
        final data = artistDoc.data() as Map<String, dynamic>;

        // Fetch URLs for picture and signature
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
        throw Exception('Artist document does not exist');
      }
    } catch (e) {
      print('Error fetching artist data: $e');
      rethrow; // Rethrow the error to be caught in the FutureBuilder
    }
  }

  Future<String> _loadSvgFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to load SVG');
    }
  }

  Future<void> _getAndroidVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    print('Android version: ${androidInfo.version.release}');
    print('SDK Int: ${androidInfo.version.sdkInt}');
  }

  Future<void> _download(BuildContext context) async {
    setState(() {
      _isDownloading = true;
    });
    _getAndroidVersion();
    // Check both permissions
    var photoStatus = await Permission.photos.status;
    var storageStatus = await Permission.manageExternalStorage.status;

    debugPrint('Initial photo permission status: $photoStatus');
    debugPrint('Initial storage permission status: $storageStatus');

    if (photoStatus.isDenied) {
      if (Platform.isAndroid) {
        photoStatus = await Permission.photos.request();
        debugPrint('Android Photo permission request result: $photoStatus');
      } else if (Platform.isIOS) {
        photoStatus = await Permission.photosAddOnly.request();
        debugPrint('iOS Photo permission request result: $photoStatus');
      }
    }

    if (Platform.isAndroid && storageStatus.isDenied) {
      storageStatus = await Permission.manageExternalStorage.request();
      debugPrint('Android Storage permission request result: $storageStatus');
    }

    if (PermissionHelper.areRequiredPermissionsGranted(
        photoStatus, storageStatus)) {
      debugPrint('All permissions granted, proceeding with download');
      try {
        _vectorUrl ??= await CachedUrlFetcher.getImageUrl(widget.rawVectorUrl);
        // Get screen size
        final Size screenSize = MediaQuery.of(context).size;
        final double pixelRatio = MediaQuery.of(context).devicePixelRatio;
        final int width = (screenSize.width * pixelRatio).toInt();
        final int height = (screenSize.height * pixelRatio).toInt();

        // Create a custom paint for rendering
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        // Draw black background
        final paint = Paint()..color = Colors.black;
        canvas.drawRect(
            Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()), paint);

        // Load and draw SVG
        final svgString = await _loadSvgFromUrl(_vectorUrl!);
        final svgDrawableRoot = await svg.fromSvgString(svgString, _vectorUrl!);
        final svgSize = svgDrawableRoot.viewport.size;
        final scale =
            (width - 200) / svgSize.width; // 10px padding on each side
        final scaledSvgHeight = svgSize.height * scale;
        final matrix = Matrix4.identity()
          ..translate((width - svgSize.width * scale) / 2,
              (height - scaledSvgHeight) / 2)
          ..scale(scale);
        canvas.transform(matrix.storage);
        svgDrawableRoot.draw(
            canvas, Rect.fromLTWH(0, 0, svgSize.width, svgSize.height));

        // Add translation text if checkbox is checked
        if (_addTranslation) {
          final textPainter = TextPainter(
            text: TextSpan(
              text: widget.translationText,
              style: TextStyle(color: Colors.grey, fontSize: 50),
            ),
            textDirection: TextDirection.ltr,
          );
          textPainter.layout(maxWidth: width.toDouble());
          final textY =
              (height + scaledSvgHeight) / 2 + 20; // 20 pixels below the SVG
          textPainter.paint(
              canvas, Offset(((width - textPainter.width) / 2) + 30, textY));
        }

        // Convert to image
        final picture = recorder.endRecording();
        final img = await picture.toImage(width, height);
        await _saveImageToGallery(img);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wallpaper saved in image gallery')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save wallpaper: $e')),
        );
      } finally {
        setState(() {
          _isDownloading = false;
        });
      }
    } else if (photoStatus.isPermanentlyDenied ||
        storageStatus.isPermanentlyDenied) {
      debugPrint('One or more permissions are permanently denied');
      openAppSettings();
    } else {
      debugPrint('One or more permissions are denied');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Both photo and storage permissions are required to save wallpapers')),
      );
    }
  }

  Future<void> _saveImageToGallery(ui.Image img) async {
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    if (pngBytes != null) {
      final result = await ImageGallerySaver.saveImage(
        pngBytes.buffer.asUint8List(),
        quality: 100,
        name: 'wallpaper_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      if (result['isSuccess']) {
        print('Image saved to gallery successfully');
      } else {
        print('Failed to save image to gallery');
      }
    } else {
      print('Failed to convert image to PNG');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(''),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FutureBuilder<String>(
                    future: _detailUrlFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error loading image'));
                      } else {
                        return Image.network(
                          snapshot.data!,
                          fit: BoxFit.contain,
                        );
                      }
                    },
                  ),
                  _buildTags(),
                  _buildArabicText(),
                  _buildTranslationText(),
                  _buildAddTranslationCheckbox(),
                  SizedBox(height: 20),
                  _buildArtistInfo(),
                ],
              ),
            ),
          ),
          _buildDownloadButton(),
        ],
      ),
    );
  }

  Widget _buildTags() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8.0,
          runSpacing: 4.0,
          children: widget.tags
              .map((tag) => Chip(
                    label: Text(tag,
                        style: TextStyle(fontSize: 12, color: Colors.white)),
                    backgroundColor: Colors.black.withOpacity(0.7),
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildArabicText() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        widget.arabicText,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  Widget _buildTranslationText() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(
        widget.translationText,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  Widget _buildAddTranslationCheckbox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Add translation (Beta)', style: TextStyle(fontSize: 16)),
          Checkbox(
            value: _addTranslation,
            onChanged: (bool? value) {
              setState(() {
                _addTranslation = value ?? false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArtistInfo() {
    if (_artistDataFuture == null) {
      return _buildUnknownArtist();
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _artistDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return _buildUnknownArtist();
        } else if (snapshot.hasData) {
          final artistData = snapshot.data!;
          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(artistData['picture_url']),
                  ),
                  SizedBox(width: 16),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(artistData['signature_url']),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Artist: ${artistData['full_name']}',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                artistData['summary'] ?? 'No summary available',
                style: TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              _buildSocialMediaLinks(artistData),
            ],
          );
        } else {
          return _buildUnknownArtist();
        }
      },
    );
  }

  Widget _buildUnknownArtist() {
    return Column(
      children: [
        Icon(Icons.account_circle, size: 80, color: Colors.grey),
        SizedBox(height: 8),
        Text(
          'Artist: Unknown',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            // TODO: Implement claim artist functionality
          },
          child: Text('Claim Artist'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey,
            side: BorderSide(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaLinks(Map<String, dynamic> artistData) {
    final socialMedia = artistData['social_media'] as Map<String, dynamic>?;
    if (socialMedia == null || socialMedia.isEmpty) {
      return SizedBox.shrink();
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: socialMedia.entries.map((entry) {
        IconData icon;
        String url = entry.value;
        switch (entry.key) {
          case 'facebook':
            icon = FontAwesomeIcons.facebook;
            url = _processSocialMediaUrl(url, 'https://www.facebook.com');
            break;
          case 'youtube':
            icon = FontAwesomeIcons.youtube;
            url = _processSocialMediaUrl(url, 'https://www.youtube.com');
            break;
          case 'instagram':
            icon = FontAwesomeIcons.instagram;
            break;
          default:
            icon = FontAwesomeIcons.link;
        }
        return InkWell(
          onTap: () => _launchUrl(url),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Text(
                entry.key,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _processSocialMediaUrl(String url, String prefix) {
    if (url.startsWith('http://')) {
      url = 'https://' + url.substring(7);
    }
    if (!url.startsWith('https://')) {
      url = 'https://' + url;
    }
    if (!url.startsWith(prefix)) {
      url = prefix + '/' + url.replaceAll(RegExp(r'^https?:\/\/(www\.)?'), '');
    }
    return url;
  }

  Future<void> _launchUrl(String url) async {
    final Uri _url = Uri.parse(url);
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }

  Widget _buildDownloadButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _isDownloading ? null : () => _download(context),
        child: _isDownloading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download, size: 24),
                  SizedBox(width: 8),
                  Text('Download Wallpaper', style: TextStyle(fontSize: 16)),
                ],
              ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
        ),
      ),
    );
  }
}
