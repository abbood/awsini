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
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final Color black = Color(0x000000);

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => WallpaperGallery()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: black,
      body: Center(
        child: SvgPicture.asset(
          'assets/logo.svg',
          width: 400, // adjust as needed
          height: 400, // adjust as needed
        ),
      ),
    );
  }
}

class WallpaperGallery extends StatelessWidget {
  final List<Map<String, String>> wallpapers = const [
    {'png': 'assets/wallpaper1.png', 'svg': 'assets/wallpaper1.svg'},
    {'png': 'assets/wallpaper2.png', 'svg': 'assets/wallpaper2.svg'},
    {'png': 'assets/wallpaper3.png', 'svg': 'assets/wallpaper3.svg'},
    {'png': 'assets/wallpaper4.png', 'svg': 'assets/wallpaper4.svg'},
    {'png': 'assets/wallpaper5.png', 'svg': 'assets/wallpaper5.svg'},
    {'png': 'assets/wallpaper6.png', 'svg': 'assets/wallpaper6.svg'},
    {'png': 'assets/wallpaper7.png', 'svg': 'assets/wallpaper7.svg'},
    {'png': 'assets/wallpaper8.png', 'svg': 'assets/wallpaper8.svg'},
    {'png': 'assets/wallpaper9.png', 'svg': 'assets/wallpaper9.svg'},
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
