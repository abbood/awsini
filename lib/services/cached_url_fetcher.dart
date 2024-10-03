import 'dart:convert';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CachedUrlFetcher {
  static const String _urlCacheKey = 'image_url_cache';
  static Map<String, String> _urlCache = {};

  static Future<void> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    _urlCache = Map<String, String>.from(prefs.getString(_urlCacheKey) != null
        ? json.decode(prefs.getString(_urlCacheKey)!)
        : {});
  }

  static Future<void> saveCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlCacheKey, json.encode(_urlCache));
  }

  static Future<String> getImageUrl(String imagePath, {String? folder}) async {
    final fullPath = folder != null ? '$folder/$imagePath' : imagePath;

    if (_urlCache.containsKey(fullPath)) {
      return _urlCache[fullPath]!;
    }

    try {
      final ref = FirebaseStorage.instance.ref().child(fullPath);
      String downloadURL = await ref.getDownloadURL();
      _urlCache[fullPath] = downloadURL;
      await saveCache();
      return downloadURL;
    } catch (e) {
      print('Error fetching image URL for $fullPath: $e');
      if (e is FirebaseException && e.code == 'object-not-found') {
        print('The file does not exist in Firebase Storage.');
      }
      return '';
    }
  }

  static Future<void> clearCache() async {
    _urlCache.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_urlCacheKey);
  }
}
