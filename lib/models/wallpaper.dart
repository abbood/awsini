// lib/models/wallpaper.dart

class Wallpaper {
  final String id;
  final String thumbnailFile;
  final String vectorFile;
  final String detailFile;
  final String translation;
  final String? artistId;
  final String ar;
  final List<String> tags;
  final Map<String, WallpaperVariation>? variations;

  Wallpaper({
    required this.id,
    required this.thumbnailFile,
    required this.vectorFile,
    required this.detailFile,
    required this.translation,
    this.artistId,
    required this.ar,
    required this.tags,
    this.variations,
  });
}

class WallpaperVariation {
  final String detail;
  final String vector;

  WallpaperVariation({
    required this.detail,
    required this.vector,
  });
}
