import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PDFViewerPage extends StatefulWidget {
  final String assetPath;

  const PDFViewerPage({super.key, required this.assetPath});

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  String? localPDFPath;

  @override
  void initState() {
    super.initState();
    _loadPdfFromAsset(widget.assetPath);
  }

  Future<void> _loadPdfFromAsset(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File("${tempDir.path}/temp_pdf.pdf");
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      setState(() {
        localPDFPath = tempFile.path;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Errore durante il caricamento del PDF: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Termini e Condizioni"),
      ),
      body: localPDFPath == null
          ? const Center(child: CircularProgressIndicator())
          : PDFView(filePath: localPDFPath!),
    );
  }
}
