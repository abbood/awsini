import 'package:awsini/models/wallpaper.dart';

class WallpaperHelpers {
  static Map<String, WallpaperVariation>? parseVariations(dynamic variationsData) {
    if (variationsData == null || variationsData is! Map) {
      return null;
    }

    Map<String, WallpaperVariation> variations = {};
    variationsData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        variations[key] = WallpaperVariation(
          detail: value['detail'] ?? '',
          vector: value['vector'] ?? '',
        );
      }
    });

    return variations.isNotEmpty ? variations : null;
  }
}
