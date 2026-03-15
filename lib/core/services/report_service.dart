import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_science_academy/features/admin_panel/presentation/screens/admin_class_report_screen.dart';

class ReportService {
  
  // 1. INDIVIDUAL STUDENT RESULT CARD PDF
  static Future<void> generateIndividualStudentCardPdf({
    required StudentFullReport student,
    required List<dynamic> subjects,
    required String reportTitle,
    required BuildContext context,
  }) async {
    try {
      final pdf = pw.Document();

      // Logo loading with error handling
      pw.MemoryImage? logo;
      try {
        final logoData = await rootBundle.load('assets/images/logo.png');
        logo = pw.MemoryImage(logoData.buffer.asUint8List());
      } catch (e) {
        debugPrint("Logo not found, skipping: $e");
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context pwContext) {
            return pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.indigo, width: 1.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, // Fixed Conflict
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("UNIVERSAL SCIENCE ACADEMY",
                              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                          pw.Text("& COLLEGE - OFFICIAL REPORT",
                              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),
                      if (logo != null) pw.Image(logo, width: 50, height: 50),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(thickness: 1, color: PdfColors.grey300),
                  pw.SizedBox(height: 20),

                  // --- STUDENT INFO ---
                  _pdfHeaderLabel("STUDENT DETAILS"),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, // Fixed Conflict
                    children: [
                      _pdfInfoTile("Name", student.studentName),
                      _pdfInfoTile("Roll Number", student.rollNumber),
                      _pdfInfoTile("Report", reportTitle.split('(')[0]),
                    ],
                  ),
                  pw.SizedBox(height: 30),

                  // --- MARKS TABLE ---
                  _pdfHeaderLabel("ACADEMIC PERFORMANCE"),
                  pw.SizedBox(height: 10),
                  pw.Table.fromTextArray(
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                    headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo700),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellAlignment: pw.Alignment.centerLeft,
                    headers: ['Subject', 'Obtained', 'Total', '%'],
                    data: subjects.map((sub) {
                      final sId = sub.id;
                      return [
                        sub['name'],
                        (student.subjectObtainedMarks[sId] ?? 0).toStringAsFixed(1),
                        (student.subjectTotalMarks[sId] ?? 0).toStringAsFixed(0),
                        "${(student.subjectPercentage[sId] ?? 0).toStringAsFixed(1)}%"
                      ];
                    }).toList(),
                  ),

                  pw.SizedBox(height: 30),

                  // --- SUMMARY ---
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceAround, // Fixed Conflict
                      children: [
                        _pdfSummaryItem("Total Marks", "${student.grandObtainedMarks.toStringAsFixed(1)} / ${student.grandTotalMarks.toStringAsFixed(0)}"),
                        _pdfSummaryItem("Percentage", "${student.overallPercentage.toStringAsFixed(2)}%"),
                        _pdfSummaryItem("Grade", _calculateGrade(student.overallPercentage)),
                      ],
                    ),
                  ),

                  pw.Spacer(),
                  pw.Align(
                    alignment: pw.Alignment.center,
                    child: pw.Text("Powered by HelloWorld", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                  ),
                ],
              ),
            );
          },
        ),
      );

      await Printing.sharePdf(bytes: await pdf.save(), filename: 'Result_${student.rollNumber}.pdf');
    } catch (e) {
      debugPrint("PDF Error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  // 2. CONSOLIDATED CLASS REPORT PDF
  static Future<void> generateAndSharePdf(
    List<StudentFullReport> rankedStudents,
    List<dynamic> subjects,
    String reportTitle,
    BuildContext context,
  ) async {
    final pdf = pw.Document();

    final headers = ['Rank', 'Roll No', 'Name'];
    for (var sub in subjects) { headers.add(sub['name']); }
    headers.addAll(['Total', '%']);

    final data = rankedStudents.asMap().entries.map((entry) {
      final rank = entry.key + 1;
      final student = entry.value;
      List<String> row = [rank.toString(), student.rollNumber, student.studentName];
      
      for (var sub in subjects) {
        row.add("${student.subjectObtainedMarks[sub.id]?.toStringAsFixed(1) ?? '0'}");
      }
      row.add("${student.grandObtainedMarks.toStringAsFixed(1)}");
      row.add("${student.overallPercentage.toStringAsFixed(1)}%");
      return row;
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context pwContext) => [
          pw.Text(reportTitle, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            cellStyle: const pw.TextStyle(fontSize: 8),
            border: pw.TableBorder.all(color: PdfColors.grey),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          ),
        ],
      ),
    );

    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Class_Report.pdf');
  }

  // --- PRIVATE HELPERS ---
  static pw.Widget _pdfHeaderLabel(String label) => pw.Text(label, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600));

  static pw.Widget _pdfInfoTile(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500)),
        pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _pdfSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.indigo700)),
        pw.Text(value, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static String _calculateGrade(double per) {
    if (per >= 80) return "A+";
    if (per >= 70) return "A";
    if (per >= 60) return "B";
    if (per >= 50) return "C";
    return "Fail";
  }
}