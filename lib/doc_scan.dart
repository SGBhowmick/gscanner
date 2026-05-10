import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gscanner/settings.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gscanner/watermark_notifier.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_filex/open_filex.dart';

class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  List<String> _scannedImagePaths = [];
  int _currentPage = 0;
  List<String> _recentFiles = [];
  static const String _recentFilesKey = 'recent_files';

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _recentFiles = prefs.getStringList(_recentFilesKey) ?? [];
      });
    } catch (e) {
      print("Error loading recent files: $e");
    }
  }

  Future<void> _saveRecentFile(String newFilePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedFiles = [
        newFilePath,
        ..._recentFiles.where((f) => f != newFilePath),
      ];
      _recentFiles = updatedFiles.take(10).toList();
      await prefs.setStringList(_recentFilesKey, _recentFiles);
      setState(() {});
    } catch (e) {
      print("Error saving recent file: $e");
    }
  }

  Future<void> _removeRecentFile(String pathToRemove) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _recentFiles.remove(pathToRemove);
      });
      await prefs.setStringList(_recentFilesKey, _recentFiles);
    } catch (e) {
      print("Error removing recent file: $e");
    }
  }

  Future<void> _clearRecentFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentFilesKey);
      setState(() {
        _recentFiles = [];
      });
      _showMsg("Recent files cleared.");
    } catch (e) {
      print("Error clearing recent files: $e");
    }
  }

  Future<void> _startScan() async {
    try {
      final DocumentScanner documentScanner = DocumentScanner(
        options: DocumentScannerOptions(
          pageLimit: 20,
          mode: ScannerMode.full,
          isGalleryImport: true,
          documentFormat: DocumentFormat.jpeg,
        ),
      );

      final DocumentScanningResult result = await documentScanner
          .scanDocument();

      final List<String> images = result.images;
      if (!mounted) return;
      setState(() {
        _scannedImagePaths.addAll(images);
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      if (e.code == 'USER_CANCELLED') {
        _showMsg('Scan cancelled.');
      } else {
        _showMsg('Error: ${e.message}');
      }
    }
  }

  Future<String?> _askForFilename(String defaultName) async {
    String? name = defaultName;
    if (name.contains('.')) {
      name = name.split('.').first;
    }

    return await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: name);
        return AlertDialog(
          title: const Text("Save File"),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: "Filename"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveAsJPEG() async {
    if (_scannedImagePaths.isEmpty) {
      _showMsg("No document scanned to save.");
      return;
    }

    final String currentFilePath = _scannedImagePaths[_currentPage];
    final Uint8List fileBytes = await File(currentFilePath).readAsBytes();

    final String? customName = await _askForFilename('Scan_Image');
    if (customName == null || customName.isEmpty) {
      _showMsg("Save cancelled.");
      return;
    }
    final String finalFileName = '$customName.jpeg';

    try {
      String? savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save JPEG',
        fileName: finalFileName,
        bytes: fileBytes,
      );

      if (savedPath != null) {
        await _saveRecentFile(savedPath);
        _showMsg("JPEG saved successfully");
      } else {
        _showMsg("Save cancelled.");
      }
    } catch (e) {
      _showMsg("Error saving JPEG: $e");
    }
  }

  Future<void> _saveAsPDF() async {
    if (_scannedImagePaths.isEmpty) {
      _showMsg("No document scanned to save.");
      return;
    }

    final watermarkNotifier = context.read<WatermarkNotifier>();

    final PdfPageFormat? formatChoice = await _showPageFormatDialog();
    if (formatChoice == null) {
      if (!await _confirmOriginalSize()) {
        _showMsg("Save cancelled.");
        return;
      }
    }

    final String? customName = await _askForFilename('Scanned_Doc');
    if (customName == null || customName.isEmpty) {
      _showMsg("Save cancelled.");
      return;
    }
    final String finalFileName = '$customName.pdf';

    try {
      final pdf = pw.Document();

      for (final path in _scannedImagePaths) {
        final bytes = await File(path).readAsBytes();
        final img = pw.MemoryImage(bytes);

        final PdfPageFormat formatToUse =
            formatChoice ??
            PdfPageFormat(
              img.width!.toDouble(),
              img.height!.toDouble(),
              marginAll: 0,
            );

        pdf.addPage(
          pw.Page(
            margin: const pw.EdgeInsets.all(0),
            pageFormat: formatToUse,
            build: (context) {
              return pw.Stack(
                children: [
                  pw.Image(img),
                  if (watermarkNotifier.isEnabled)
                    pw.Positioned(
                      bottom: 10,
                      right: 10,
                      child: pw.Opacity(
                        opacity: watermarkNotifier.opacity,
                        child: pw.Row(
                          children: [
                            pw.Text(
                              watermarkNotifier.text,
                              style: pw.TextStyle(
                                font: watermarkNotifier.getPwFont(),
                                fontSize: watermarkNotifier.fontSize,
                                color: watermarkNotifier.getPdfColor(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      }

      final Uint8List pdfBytes = await pdf.save();

      String? savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save PDF',
        fileName: finalFileName,
        bytes: pdfBytes,
      );

      if (savedPath != null) {
        await _saveRecentFile(savedPath);
        _showMsg("PDF saved successfully");
        setState(() {
          _scannedImagePaths = [];
          _currentPage = 0;
        });
      } else {
        _showMsg("Save cancelled.");
      }
    } catch (e) {
      _showMsg("Error saving PDF: $e");
      print("PDF Save Error: $e");
    }
  }

  Future<bool> _confirmOriginalSize() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Page Size'),
            content: const Text(
              'You selected "Original Image Size". Is this correct?',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<PdfPageFormat?> _showCustomSizeInputDialog(
    BuildContext context,
  ) async {
    final widthController = TextEditingController();
    final heightController = TextEditingController();

    return await showDialog<PdfPageFormat>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Custom Page Size (mm)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: widthController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Width (mm)"),
            ),
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Height (mm)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              final w = double.tryParse(widthController.text);
              final h = double.tryParse(heightController.text);
              if (w != null && h != null) {
                final format = PdfPageFormat(
                  w * PdfPageFormat.mm,
                  h * PdfPageFormat.mm,
                );
                Navigator.pop(context, format);
              }
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<PdfPageFormat?> _showPageFormatDialog() async {
    return await showDialog<PdfPageFormat?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Page Format'),
        children: [
          _buildFormatOption(context, 'Original Image Size', null),
          SimpleDialogOption(
            onPressed: () async {
              final customFormat = await _showCustomSizeInputDialog(context);
              if (customFormat != null && context.mounted) {
                Navigator.pop(context, customFormat);
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                "Custom Size (Type...)",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          _buildFormatOption(context, 'A4 (Default)', PdfPageFormat.a4),
          _buildFormatOption(context, 'A5', PdfPageFormat.a5),
          _buildFormatOption(context, 'US Letter', PdfPageFormat.letter),
          _buildFormatOption(context, 'US Legal', PdfPageFormat.legal),
        ],
      ),
    );
  }

  Widget _buildFormatOption(
    BuildContext context,
    String title,
    PdfPageFormat? format,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.pop(context, format);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(title, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // --- NEW: Discard Scan Logic ---
  void _discardScan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Discard Scan?"),
        content: const Text("This will clear the current scanned images."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _scannedImagePaths = [];
                _currentPage = 0;
              });
            },
            child: const Text("Discard", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool showFab = _scannedImagePaths.isEmpty && _recentFiles.isNotEmpty;

    return Scaffold(
      backgroundColor: isIOS
          ? (isDark ? Colors.black : Colors.white.withOpacity(0.7))
          : Theme.of(context).colorScheme.background,
      appBar: AppBar(
        // --- NEW: Show Close button when scanning ---
        leading: _scannedImagePaths.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Discard Scan',
                onPressed: _discardScan,
              )
            : null,
        title: const Text('Document Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
        backgroundColor: isIOS ? Colors.transparent : null,
        elevation: isIOS ? 0 : null,
      ),
      body: isIOS ? _iosGlassUI() : _androidMaterialUI(),
      floatingActionButton: showFab
          ? FloatingActionButton.extended(
              onPressed: _startScan,
              label: const Text("Scan Document"),
              icon: const Icon(Icons.document_scanner),
            )
          : null,
    );
  }

  Widget _iosGlassUI() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.3),
                    ]
                  : [
                      Colors.white.withOpacity(0.25),
                      Colors.white.withOpacity(0.1),
                    ],
            ),
          ),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.transparent),
        ),
        SafeArea(
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _androidMaterialUI() {
    return SafeArea(
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_scannedImagePaths.isNotEmpty) {
      return _buildPreview(key: const ValueKey('preview'));
    } else if (_recentFiles.isNotEmpty) {
      return _buildRecentFilesList(key: const ValueKey('recents'));
    } else {
      return _buildEmptyState(key: const ValueKey('empty'));
    }
  }

  Widget _buildRecentFilesList({Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent Files",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text("Clear All"),
                onPressed: _clearRecentFiles,
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: _recentFiles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final filePath = _recentFiles[index];
              return _buildRecentFileGridItem(filePath);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFileGridItem(String filePath) {
    String decodedPath = Uri.decodeFull(filePath);

    final String fileName = decodedPath.split(Platform.pathSeparator).last;

    String rawDirectory = decodedPath;
    if (decodedPath.length > fileName.length) {
      rawDirectory = decodedPath.substring(
        0,
        decodedPath.length - fileName.length,
      );
    }

    String displayDirectory = rawDirectory;

    if (displayDirectory.contains('/primary:')) {
      displayDirectory = displayDirectory.split('/primary:').last;
      if (displayDirectory.startsWith('/')) {
        displayDirectory = displayDirectory.substring(1);
      }
      displayDirectory = "Internal Storage > $displayDirectory";
    } else if (displayDirectory.contains('/0/')) {
      displayDirectory = displayDirectory.split('/0/').last;
      displayDirectory = "Internal Storage > $displayDirectory";
    } else if (displayDirectory.contains('content://')) {
      displayDirectory = "System Storage (Secure)";
    } else if (displayDirectory.startsWith('/document/')) {
      displayDirectory = displayDirectory.replaceAll(
        '/document/',
        'Storage > ',
      );
    }

    if (displayDirectory.endsWith('/') && displayDirectory.length > 1) {
      displayDirectory = displayDirectory.substring(
        0,
        displayDirectory.length - 1,
      );
    }

    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    final fileExtension = isPdf ? 'PDF' : 'JPG';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: isDark ? 1.0 : 2.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isDark
            ? BorderSide(color: Colors.grey[800]!, width: 0.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          final result = await OpenFilex.open(filePath);
          if (result.type != ResultType.done && mounted) {
            if (result.type == ResultType.fileNotFound) {
              _showMsg("File not found. Removing...");
              await _removeRecentFile(filePath);
            } else {
              _showMsg("Cannot open: ${result.message}");
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Icon(
                    isPdf
                        ? Icons.picture_as_pdf_outlined
                        : Icons.image_outlined,
                    color: isPdf ? Colors.red.shade400 : Colors.blue.shade400,
                    size: 50.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        fileExtension,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text(
                fileName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.0,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8.0),
              Text(
                displayDirectory,
                style: TextStyle(
                  fontSize: 11.0,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 100,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ),
          const SizedBox(height: 24),
          Text(
            "Tap 'Scan Document' to get started.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 40),
          FilledButton.icon(
            icon: const Icon(Icons.document_scanner),
            label: const Text("Scan Document"),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
              textStyle: Theme.of(context).textTheme.titleMedium,
            ),
            onPressed: _startScan,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview({Key? key}) {
    final watermarkNotifier = context.watch<WatermarkNotifier>();

    return Column(
      key: key,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Page ${_currentPage + 1} of ${_scannedImagePaths.length}",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: PageView.builder(
            itemCount: _scannedImagePaths.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (_, i) => Container(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(_scannedImagePaths[i]),
                      fit: BoxFit.contain,
                    ),
                    if (watermarkNotifier.isEnabled)
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: IgnorePointer(
                          child: Text(
                            watermarkNotifier.text,
                            style: watermarkNotifier.getFlutterTextStyle(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Save as PDF"),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _saveAsPDF,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.image_outlined),
                      label: const Text("Save Page (JPEG)"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _saveAsJPEG,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: const Text("Scan More"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _startScan,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openSettings() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }
}
