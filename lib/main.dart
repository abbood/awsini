import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:device_info_plus/device_info_plus.dart';
import 'widgets/wallpaper_detail_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    );
  }
}

class WallpaperGallery extends StatelessWidget {
  final List<Map<String, String>> wallpapers = const [
    {'png': 'assets/wallpaper1.png', 'svg': 'assets/wallpaper1.svg','detail': 'assets/wallpaper1_detail.png','translation':"Didn't he know that Allah sees"},
    {'png': 'assets/wallpaper2.png', 'svg': 'assets/wallpaper2.svg','detail': 'assets/wallpaper2_detail.png','translation':"Work; and God will surely see your work"},
    {'png': 'assets/wallpaper3.png', 'svg': 'assets/wallpaper3.svg','detail': 'assets/wallpaper3_detail.png','translation':"Despair not of the mercy of Allah"},
    {'png': 'assets/wallpaper4.png', 'svg': 'assets/wallpaper4.svg','detail': 'assets/wallpaper4_detail.png','translation':"Say to the believers they should lower their gaze"},
    {'png': 'assets/wallpaper5.png', 'svg': 'assets/wallpaper5.svg','detail': 'assets/wallpaper5_detail.png','translation':"Persevere and endure and remain stationed"},
    {'png': 'assets/wallpaper6.png', 'svg': 'assets/wallpaper6.svg','detail': 'assets/wallpaper6_detail.png','translation':"Grant me the power and ability that I may be grateful for Your favors which You have bestowed on me and on my parents"},
    {'png': 'assets/wallpaper7.png', 'svg': 'assets/wallpaper7.svg','detail': 'assets/wallpaper7_detail.png','translation':"Indeed the promise of Allah is truth"},
    {'png': 'assets/wallpaper8.png', 'svg': 'assets/wallpaper8.svg','detail': 'assets/wallpaper8_detail.png','translation':"Life is but an hour, fill it with obedience"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallpaper Gallery'),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 9 / 16,
        ),
        itemCount: wallpapers.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WallpaperDetailPage(
                    pngPath: wallpapers[index]['png']!,
                    svgPath: wallpapers[index]['svg']!,
                    detailPath: wallpapers[index]['detail']!,
                    translationText: wallpapers[index]['translation']!,
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                wallpapers[index]['png']!,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}
