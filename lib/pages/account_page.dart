import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Account')),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            leading: Icon(Icons.settings),
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
      ),
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
}
