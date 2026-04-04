import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'pdf_report_service.dart';

class PdfPreviewScreen extends StatelessWidget {
  final File file;

  const PdfPreviewScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Preview Report")),

      body: PdfPreview(build: (format) async => file.readAsBytes()),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40), // 👈 adjust height
        child: FloatingActionButton(
          child: const Icon(Icons.download),
          onPressed: () async {
            await PdfReportService().saveToDownloads(file);

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Saved to Downloads")));
          },
        ),
      ),
    );
  }
}
