import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/theme_provider.dart';

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account')),
      body: ListView(
        children: [
          _buildSettingsSection(context),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildThemeButton(
                        context,
                        'System',
                        ThemeMode.system,
                        themeProvider,
                      ),
                      _buildThemeButton(
                        context,
                        'Light',
                        ThemeMode.light,
                        themeProvider,
                      ),
                      _buildThemeButton(
                        context,
                        'Dark',
                        ThemeMode.dark,
                        themeProvider,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(
            'About',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ListTile(
          title: Text('Privacy Policy'),
          onTap: () => _launchUrl('https://www.awsini.com/privacy'),
        ),
        ListTile(
          title: Text('Terms of Service'),
          onTap: () => _launchUrl('https://www.awsini.com/terms'),
        ),
      ],
    );
  }

  Widget _buildThemeButton(
    BuildContext context,
    String title,
    ThemeMode themeMode,
    ThemeProvider themeProvider,
  ) {
    final isSelected = themeProvider.themeMode == themeMode;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          themeProvider.setThemeMode(themeMode);
        }
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
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
