import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart' as pdf_color;
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';

enum PdfFont { helvetica, times, courier }

class WatermarkNotifier extends ChangeNotifier {
  static const String _enabledKey = 'wm_isEnabled';
  static const String _textKey = 'wm_text';
  static const String _fontKey = 'wm_font';
  static const String _fontSizeKey = 'wm_fontSize';
  static const String _opacityKey = 'wm_opacity';
  static const String _colorKey = 'wm_color';

  static const bool _defaultEnabled = true;
  static const String _defaultText = "Scanned by GBScanner";
  static const PdfFont _defaultFont = PdfFont.helvetica;
  static const double _defaultFontSize = 24.0;
  static const double _defaultOpacity = 0.3;
  static final Color _defaultColor = Colors.grey[700]!;

  bool _isEnabled;
  String _text;
  PdfFont _font;
  double _fontSize;
  double _opacity;
  Color _color;

  bool get isEnabled => _isEnabled;
  String get text => _text;
  PdfFont get font => _font;
  double get fontSize => _fontSize;
  double get opacity => _opacity;
  Color get color => _color;

  WatermarkNotifier({
    required bool initialEnabled,
    required String initialText,
    required PdfFont initialFont,
    required double initialFontSize,
    required double initialOpacity,
    required Color initialColor,
  }) : _isEnabled = initialEnabled,
       _text = initialText,
       _font = initialFont,
       _fontSize = initialFontSize,
       _opacity = initialOpacity,
       _color = initialColor;

  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<void> setText(String value) async {
    _text = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_textKey, value);
  }

  Future<void> setFont(PdfFont value) async {
    _font = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, value.name);
  }

  Future<void> setFontSize(double value) async {
    _fontSize = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, value);
  }

  Future<void> setOpacity(double value) async {
    _opacity = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_opacityKey, value);
  }

  Future<void> setColor(Color value) async {
    _color = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_colorKey, value.value);
  }

  static Future<Map<String, dynamic>> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fontName = prefs.getString(_fontKey) ?? _defaultFont.name;

      return {
        'initialEnabled': prefs.getBool(_enabledKey) ?? _defaultEnabled,
        'initialText': prefs.getString(_textKey) ?? _defaultText,
        'initialFont': PdfFont.values.firstWhere(
          (e) => e.name == fontName,
          orElse: () => _defaultFont,
        ),
        'initialFontSize': prefs.getDouble(_fontSizeKey) ?? _defaultFontSize,
        'initialOpacity': prefs.getDouble(_opacityKey) ?? _defaultOpacity,
        'initialColor': prefs.getInt(_colorKey) ?? _defaultColor.value,
      };
    } catch (e) {
      print("Failed to load watermark settings: $e");
      return {
        'initialEnabled': _defaultEnabled,
        'initialText': _defaultText,
        'initialFont': _defaultFont,
        'initialFontSize': _defaultFontSize,
        'initialOpacity': _defaultOpacity,
        'initialColor': _defaultColor.value,
      };
    }
  }

  pw.Font getPwFont() {
    switch (_font) {
      case PdfFont.times:
        return pw.Font.times();
      case PdfFont.courier:
        return pw.Font.courier();
      case PdfFont.helvetica:
        return pw.Font.helvetica();
    }
  }

  pdf_color.PdfColor getPdfColor() {
    return pdf_color.PdfColor.fromInt(_color.value);
  }

  String getFontName(PdfFont font) {
    switch (font) {
      case PdfFont.times:
        return "Times New Roman";
      case PdfFont.courier:
        return "Courier";
      case PdfFont.helvetica:
        return "Helvetica (Default)";
    }
  }

  TextStyle getFlutterTextStyle() {
    String? fontFamily;
    switch (_font) {
      case PdfFont.times:
        fontFamily = 'serif';
      case PdfFont.courier:
        fontFamily = 'monospace';
      case PdfFont.helvetica:
        fontFamily = 'sansSerif';
    }

    return TextStyle(
      fontFamily: fontFamily,
      fontSize: _fontSize,
      color: _color.withOpacity(_opacity),
    );
  }
}
