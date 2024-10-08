import 'package:awsini/pages/account_page.dart';
import 'package:awsini/pages/explore_page.dart';
import 'package:awsini/pages/favorites_page.dart';
import 'package:awsini/services/cached_url_fetcher.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'providers/theme_provider.dart';
import 'widgets/welcome_carousel.dart';

void main() async {
  print("Starting app initialization");
  WidgetsFlutterBinding.ensureInitialized();
  print("Flutter binding initialized");
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
  await CachedUrlFetcher.loadCache();
  print("Running app");
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: WallpaperMarketplaceApp(),
    ),
  );
}

class WallpaperMarketplaceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Wallpaper Marketplace',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          home: MainScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1; // Start with Explore page
  bool _showWelcome = true;
  final List<Widget> _pages = [
    FavoritesPage(),
    ExplorePage(),
    AccountPage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkFirstSeen();
  }

  Future<void> _checkFirstSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool _seen = (prefs.getBool('seen') ?? false);
    if (_seen) {
      setState(() {
        _showWelcome = false;
      });
    }
  }

  void _onWelcomeComplete() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen', true);
    setState(() {
      _showWelcome = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDarkMode = theme.brightness == Brightness.dark;

    return _showWelcome
        ? WelcomeCarousel(onComplete: _onWelcomeComplete)
        : Scaffold(
            body: _pages[_currentIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              selectedItemColor: theme.colorScheme.primary,
              unselectedItemColor: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              items: [
                _buildNavItem(Icons.favorite, 'Favorites', 0),
                _buildNavItem(Icons.explore, 'Explore', 1),
                _buildNavItem(Icons.account_circle, 'Account', 2),
              ],
            ),
          );
  }

  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Icon(
        icon,
        size: _currentIndex == index ? 28 : 24,
      ),
      label: label,
    );
  }
}
