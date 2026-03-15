import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ListExportService {
  static Future<void> generateStudentListPdf({
    required BuildContext context,
    required String className,
    required String groupName, // Jaise "All Students", "Biology Group"
    required List<QueryDocumentSnapshot> students,
  }) async {
    if (students.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No students to export.")));
      return;
    }

    final pdf = pw.Document();
    final String reportTitle = "Student List: $className";
    final String subTitle = "Group: $groupName";

    // --- UPDATED: Phone Number ka header add karein ---
    final headers = [
      'S.No',
      'Roll No.',
      'Student Name',
      'Father Name',
      'Phone Number', // NEW
      'Group',
    ];

    // --- UPDATED: Phone Number ka data add karein ---
    final data = students.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final studentData = entry.value.data() as Map<String, dynamic>;
      return [
        index.toString(),
        studentData['rollNumber'] ?? 'N/A',
        studentData['name'] ?? 'N/A',
        studentData['fatherName'] ?? 'N/A',
        studentData['phoneNumber'] ?? 'N/A', // NEW
        studentData['studentGroup'] ?? 'N/A',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        header: (context) => _buildHeader(reportTitle, subTitle),
        build: (context) => [
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            border: pw.TableBorder.all(),
            // --- UPDATED: Naye column ke liye alignment add karein ---
            cellAlignments: {
              0: pw.Alignment.center,
              1: pw.Alignment.center,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerLeft,
              4: pw.Alignment.centerLeft, // NEW
              5: pw.Alignment.center,
            },
            // --- UPDATED: Naye column ke liye width adjust karein ---
            columnWidths: {
              0: const pw.FlexColumnWidth(0.5),
              1: const pw.FlexColumnWidth(0.8),
              2: const pw.FlexColumnWidth(1.8),
              3: const pw.FlexColumnWidth(1.8),
              4: const pw.FlexColumnWidth(1.5), // NEW
              5: const pw.FlexColumnWidth(1.2),
            },
          ),
        ],
      ),
    );

    try {
      final pdfBytes = await pdf.save();
      final fileName =
          '${reportTitle.replaceAll(' ', '_')}_${groupName.replaceAll(' ', '_')}.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error generating PDF: $e")));
    }
  }

  static pw.Widget _buildHeader(String title, String subTitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(subTitle, style: const pw.TextStyle(fontSize: 16)),
        pw.Divider(thickness: 1.5),
        pw.SizedBox(height: 20),
      ],
    );
  }
}
