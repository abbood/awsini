import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

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
  final Color darkGray = Color(0xFF080808);

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
      backgroundColor: darkGray,
      body: Center(
        child: Image.asset('assets/logo.png'),
      ),
    );
  }
}

class WallpaperGallery extends StatelessWidget {
  final List<String> wallpapers = const [
    'assets/wallpaper1.png',
    'assets/wallpaper2.png',
    'assets/wallpaper3.png',
    'assets/wallpaper4.png',
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
                  builder: (context) =>
                      WallpaperDetailPage(wallpaperPath: wallpapers[index]),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                wallpapers[index],
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }
}

class WallpaperDetailPage extends StatelessWidget {
  final String wallpaperPath;

  WallpaperDetailPage({required this.wallpaperPath});

  Future<void> _getAndroidVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    print('Android version: ${androidInfo.version.release}');
    print('SDK Int: ${androidInfo.version.sdkInt}');
  }

  Future<void> _download(BuildContext context) async {
    _getAndroidVersion();
    // First, check the permission status
    var status = await Permission.photos.status;
    debugPrint('Initial permission status: $status');
    if (status.isDenied) {
      // If permission is denied, request it
      debugPrint('Permission is denied, requesting permission...');
      status = await Permission.photos.request();
      debugPrint('Permission request result: $status');
    }

    if (status.isGranted) {
      // Permission granted, proceed with download
      debugPrint('Permission is granted, proceeding with download');
      try {
        final directory = await getExternalStorageDirectory();
        final wallpaperName = wallpaperPath.split('/').last;
        final savePath = '${directory!.path}/$wallpaperName';

        final byteData = await rootBundle.load(wallpaperPath);

        final file = File(savePath);
        await file.writeAsBytes(byteData.buffer
            .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wallpaper saved to: $savePath')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save wallpaper: $e')),
        );
      }
    } else if (status.isPermanentlyDenied) {
      // The user opted to never again see the permission request dialog for this
      // app. The only way to change the permission's status now is to let the
      // user manually enable it in the system settings.
      debugPrint('Permission is permanently denied');
      openAppSettings();
    } else {
      // Permission denied
      debugPrint('Permission is denied');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Storage permission is required to save wallpapers')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wallpaper Detail'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 5,
            width: double.infinity,
            child: ClipRect(
              child: OverflowBox(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Image.asset(wallpaperPath),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton(
              child: Text('Download'),
              onPressed: () => _download(context),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
