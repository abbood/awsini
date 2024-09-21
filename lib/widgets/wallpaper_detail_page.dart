import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:awsini/helpers/permission_helper.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class WallpaperDetailPage extends StatefulWidget {
  final String pngPath;
  final String svgPath;
  final String detailPath;
  final String translationText;

  WallpaperDetailPage(
      {required this.pngPath,
      required this.svgPath,
      required this.detailPath,
      required this.translationText});

  @override
  _WallpaperDetailPageState createState() => _WallpaperDetailPageState();
}

class _WallpaperDetailPageState extends State<WallpaperDetailPage> {
  bool _addTranslation = false;

  Future<void> _getAndroidVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    print('Android version: ${androidInfo.version.release}');
    print('SDK Int: ${androidInfo.version.sdkInt}');
  }

  Future<void> _download(BuildContext context) async {
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
        String? selectedDirectory =
            await FilePicker.platform.getDirectoryPath();
        if (selectedDirectory == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Directory selection canceled')),
          );
          return;
        }

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
        final svgDrawableRoot = await svg.fromSvgString(
            await DefaultAssetBundle.of(context).loadString(widget.svgPath),
            widget.svgPath);
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
        final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

        // Save the image
        final wallpaperName =
            'wallpaper_${DateTime.now().millisecondsSinceEpoch}.png';
        final savePath = path.join(selectedDirectory, wallpaperName);
        final file = File(savePath);
        await file.writeAsBytes(pngBytes!.buffer.asUint8List());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wallpaper saved to: $savePath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save wallpaper: $e')),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallpaper Detail'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              widget.detailPath,
              fit: BoxFit.contain,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                widget.translationText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Add translation (Beta)',
                    style: TextStyle(fontSize: 16),
                  ),
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _download(context),
        child: Icon(Icons.download),
      ),
    );
  }
}
