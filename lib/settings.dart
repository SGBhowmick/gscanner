import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gscanner/theme_notifier.dart';
import 'package:gscanner/watermark_notifier.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _watermarkTextController;

  @override
  void initState() {
    super.initState();
    _watermarkTextController = TextEditingController(
      text: context.read<WatermarkNotifier>().text,
    );
  }

  @override
  void dispose() {
    _watermarkTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();
    final watermarkNotifier = context.watch<WatermarkNotifier>();

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Theme",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
          _themeOption(
            title: "System Default",
            value: AppThemeMode.system,
            groupValue: themeNotifier.currentTheme,
            onChanged: (v) async => themeNotifier.setTheme(v),
          ),
          _themeOption(
            title: "Light",
            value: AppThemeMode.light,
            groupValue: themeNotifier.currentTheme,
            onChanged: (v) async => themeNotifier.setTheme(v),
          ),
          _themeOption(
            title: "Dark",
            value: AppThemeMode.dark,
            groupValue: themeNotifier.currentTheme,
            onChanged: (v) async => themeNotifier.setTheme(v),
          ),
          _themeOption(
            title: "AMOLED Black",
            value: AppThemeMode.amoled,
            groupValue: themeNotifier.currentTheme,
            onChanged: (v) async => themeNotifier.setTheme(v),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Watermark",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text("Enable Watermark"),
            value: watermarkNotifier.isEnabled,
            onChanged: (value) async => watermarkNotifier.setEnabled(value),
          ),
          ListTile(
            title: const Text("Watermark Text"),
            subtitle: Text(watermarkNotifier.text),
            enabled: watermarkNotifier.isEnabled,
            onTap: () {
              _watermarkTextController.text = watermarkNotifier.text;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Edit Watermark"),
                  content: TextFormField(
                    controller: _watermarkTextController,
                    decoration: const InputDecoration(
                      labelText: "Watermark Text",
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text("Cancel"),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    TextButton(
                      child: const Text("Save"),
                      onPressed: () async {
                        await watermarkNotifier.setText(
                          _watermarkTextController.text,
                        );
                        if (mounted) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            title: const Text("Font Family"),
            enabled: watermarkNotifier.isEnabled,
            trailing: DropdownButton<PdfFont>(
              value: watermarkNotifier.font,
              onChanged: (PdfFont? newValue) async {
                if (newValue != null) {
                  await watermarkNotifier.setFont(newValue);
                }
              },
              items: PdfFont.values.map((PdfFont font) {
                return DropdownMenuItem<PdfFont>(
                  value: font,
                  child: Text(watermarkNotifier.getFontName(font)),
                );
              }).toList(),
            ),
          ),
          ListTile(
            enabled: watermarkNotifier.isEnabled,
            title: const Text("Font Color"),
            trailing: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: watermarkNotifier.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                  width: 2,
                ),
              ),
            ),
            onTap: () {
              if (!watermarkNotifier.isEnabled) return;
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Pick a color'),
                  content: SingleChildScrollView(
                    child: BlockPicker(
                      pickerColor: watermarkNotifier.color,
                      onColorChanged: (color) async {
                        await watermarkNotifier.setColor(color);
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Done'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              "Font Size: ${watermarkNotifier.fontSize.toStringAsFixed(0)}",
            ),
          ),
          Slider(
            value: watermarkNotifier.fontSize,
            min: 10,
            max: 50,
            divisions: 40,
            label: watermarkNotifier.fontSize.toStringAsFixed(0),
            onChanged: watermarkNotifier.isEnabled
                ? (value) async => watermarkNotifier.setFontSize(value)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Text(
              "Opacity: ${(watermarkNotifier.opacity * 100).toStringAsFixed(0)}%",
            ),
          ),
          Slider(
            value: watermarkNotifier.opacity,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            label: (watermarkNotifier.opacity * 100).toStringAsFixed(0),
            onChanged: watermarkNotifier.isEnabled
                ? (value) async => watermarkNotifier.setOpacity(value)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required String title,
    required AppThemeMode value,
    required AppThemeMode groupValue,
    required Future<void> Function(AppThemeMode?) onChanged,
  }) {
    return RadioListTile<AppThemeMode>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: (v) => onChanged(v),
    );
  }
}
