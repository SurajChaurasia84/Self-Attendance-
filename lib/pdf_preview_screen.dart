import 'dart:io';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

import 'pdf_report_service.dart';

class PdfPreviewScreen extends StatelessWidget {
  final File file;

  const PdfPreviewScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Report')),
      body: PdfPreview(
        build: (PdfPageFormat format) async => file.readAsBytes(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: FloatingActionButton(
          child: const Icon(Icons.download),
          onPressed: () async {
            final ScaffoldMessengerState messenger = ScaffoldMessenger.of(
              context,
            );
            final double bottomInset = MediaQuery.of(context).viewPadding.bottom;

            await PdfReportService().saveToDownloads(file);

            messenger.showSnackBar(
              SnackBar(
                content: const Text('Saved to Downloads'),
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 12),
              ),
            );
          },
        ),
      ),
    );
  }
}
