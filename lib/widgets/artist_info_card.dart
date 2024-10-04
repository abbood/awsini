import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ArtistInfoCard extends StatelessWidget {
  final Map<String, dynamic> artistData;
  final VoidCallback? onViewWallpapers;

  const ArtistInfoCard({
    Key? key,
    required this.artistData,
    this.onViewWallpapers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasSignature = artistData['signature_url'] != null &&
        artistData['signature_url'].toString().trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(artistData['picture_url']),
            ),
            if (hasSignature) ...[
              SizedBox(width: 16),
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(artistData['signature_url']),
              ),
            ],
          ],
        ),
        SizedBox(height: 16),
        Text(
          'Artist: ${artistData['full_name']}',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onViewWallpapers != null) ...[
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: onViewWallpapers,
            child: Text('View Artist Wallpapers'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        SizedBox(height: 8),
        Text(
          artistData['summary'] ?? 'No summary available',
          style: TextStyle(
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 16),
        _buildSocialMediaLinks(context),
      ],
    );
  }

  Widget _buildSocialMediaLinks(BuildContext context) {
    final socialMedia = artistData['social_media'] as Map<String, dynamic>?;
    if (socialMedia == null || socialMedia.isEmpty) {
      return SizedBox.shrink();
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    final textColor = isDarkMode ? Colors.grey[300] : Colors.grey[800];

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: socialMedia.entries.map((entry) {
        IconData icon;
        String url = entry.value;
        String prefix;
        String displayText;

        switch (entry.key.toLowerCase()) {
          case 'facebook':
            icon = FontAwesomeIcons.facebook;
            prefix = 'https://www.facebook.com/';
            break;
          case 'youtube':
            icon = FontAwesomeIcons.youtube;
            prefix = 'https://www.youtube.com/';
            break;
          case 'instagram':
            icon = FontAwesomeIcons.instagram;
            prefix = 'https://www.instagram.com/';
            break;
          case 'linkedin':
            icon = FontAwesomeIcons.linkedin;
            prefix = 'https://www.linkedin.com/in/';
            break;
          case 'tiktok':
            icon = FontAwesomeIcons.tiktok;
            prefix = 'https://www.tiktok.com/@';
            break;
          case 'x':
          case 'twitter':
            icon = FontAwesomeIcons.xTwitter;
            prefix = 'https://twitter.com/';
            break;
          default:
            icon = FontAwesomeIcons.link;
            prefix = 'https://';
        }

        if (url.toLowerCase().startsWith(prefix.toLowerCase())) {
          displayText = 'sample';
        } else {
          displayText =
              url.replaceAll(RegExp(r'[/\\]'), ''); // Remove any slashes
          url = _processSocialMediaUrl(url, prefix);
        }

        return InkWell(
          onTap: () => _launchUrl(url),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: iconColor),
              SizedBox(width: 4),
              Text(
                displayText,
                style: TextStyle(color: textColor, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _processSocialMediaUrl(String url, String prefix) {
    if (url.toLowerCase().startsWith('http://') ||
        url.toLowerCase().startsWith('https://')) {
      return url;
    } else {
      return '$prefix$url';
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri _url = Uri.parse(url);
    if (!await launchUrl(_url)) {
      throw Exception('Could not launch $_url');
    }
  }
}
