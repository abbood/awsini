import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LicensesPage extends StatelessWidget {
  final List<Map<String, String>> licenses = [
    {"name": "path_provider", "url": "https://github.com/flutter/plugins/tree/main/packages/path_provider"},
    {"name": "permission_handler", "url": "https://github.com/Baseflow/flutter-permission-handler"},
    {"name": "device_info_plus", "url": "https://github.com/fluttercommunity/plus_plugins/tree/main/packages/device_info_plus"},
    {"name": "file_picker", "url": "https://github.com/miguelpruivo/flutter_file_picker"},
    {"name": "path", "url": "https://github.com/dart-lang/path"},
    {"name": "flutter_svg", "url": "https://github.com/dnfield/flutter_svg"},
    {"name": "flutter_launcher_icons", "url": "https://github.com/fluttercommunity/flutter_launcher_icons"},
    {"name": "flutter_native_splash", "url": "https://github.com/jonbhanson/flutter_native_splash"},
    {"name": "cached_network_image", "url": "https://github.com/Baseflow/flutter_cached_network_image"},
    {"name": "shared_preferences", "url": "https://github.com/flutter/plugins/tree/main/packages/shared_preferences"},
    {"name": "firebase_storage", "url": "https://github.com/firebase/flutterfire/tree/master/packages/firebase_storage"},
    {"name": "firebase_core", "url": "https://github.com/firebase/flutterfire/tree/master/packages/firebase_core"},
    {"name": "cloud_firestore", "url": "https://github.com/firebase/flutterfire/tree/master/packages/cloud_firestore"},
    {"name": "skeletonizer", "url": "https://github.com/Milad-Akarie/skeletonizer"},
    {"name": "carousel_slider", "url": "https://github.com/serenader2014/flutter_carousel_slider"},
    {"name": "provider", "url": "https://github.com/rrousselGit/provider"},
    {"name": "url_launcher", "url": "https://github.com/flutter/plugins/tree/main/packages/url_launcher"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Licenses'),
      ),
      body: ListView.builder(
        itemCount: licenses.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(licenses[index]["name"]!),
            onTap: () => _launchUrl(licenses[index]["url"]!),
          );
        },
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri _url = Uri.parse(url);
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }
}

class SlideUpRoute extends PageRouteBuilder {
  final Widget page;
  SlideUpRoute({required this.page})
      : super(
          pageBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) =>
              page,
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) =>
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
        );
}
