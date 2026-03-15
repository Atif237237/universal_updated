import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/services/database_service.dart';
import 'package:universal_science_academy/core/services/report_service.dart';
import 'package:universal_science_academy/features/admin_panel/presentation/screens/StudentIndividualResultCard.dart';

// Helper class for fully processed student report
class StudentFullReport {
  final String studentId;
  final String studentName;
  final String rollNumber;
  Map<String, double> subjectObtainedMarks = {};
  Map<String, double> subjectTotalMarks = {};
  Map<String, double> subjectPercentage = {};
  double grandObtainedMarks = 0;
  double grandTotalMarks = 0;
  double overallPercentage = 0;

  StudentFullReport({
    required this.studentId, 
    required this.studentName,
    required this.rollNumber,
  });
}

class AdminClassReportScreen extends StatelessWidget {
  final String classId;
  final String className;
  final String sessionType;
  final DateTime? selectedMonth;

  const AdminClassReportScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.sessionType,
    this.selectedMonth,
  });

  Future<Map<String, dynamic>> _getProcessedReportData(DatabaseService db) async {
    final reportData = await db.getConsolidatedReportForClass(classId);
    final List<QueryDocumentSnapshot> students = reportData['students'];
    final List<QueryDocumentSnapshot> subjects = reportData['subjects'];
    final List<QueryDocumentSnapshot> allResults = reportData['results'];

    final filteredResults = allResults.where((result) {
      var data = result.data() as Map<String, dynamic>;
      if (data['sessionType'] != sessionType) return false;
      if (sessionType == 'Monthly' && selectedMonth != null) {
        if (!data.containsKey('monthFor') || data['monthFor'] == null) return false;
        DateTime resultMonth = (data['monthFor'] as Timestamp).toDate();
        return resultMonth.year == selectedMonth!.year && resultMonth.month == selectedMonth!.month;
      }
      return true;
    }).toList();

    Map<String, StudentFullReport> studentReportMap = {};
    for (var studentDoc in students) {
      studentReportMap[studentDoc.id] = StudentFullReport(
        studentId: studentDoc.id,
        studentName: studentDoc['name'],
        rollNumber: studentDoc['rollNumber'] ?? 'N/A',
      );
    }

    for (var resultDoc in filteredResults) {
      var data = resultDoc.data() as Map<String, dynamic>;
      String studentId = data['studentId'];
      String subjectId = data['subjectId'];

      if (studentReportMap.containsKey(studentId)) {
        var report = studentReportMap[studentId]!;
        report.subjectObtainedMarks[subjectId] = (report.subjectObtainedMarks[subjectId] ?? 0) + (data['marksObtained'] as num);
        report.subjectTotalMarks[subjectId] = (report.subjectTotalMarks[subjectId] ?? 0) + (data['totalMarks'] as num);
      }
    }

    for (var report in studentReportMap.values) {
      for (var subjectId in report.subjectObtainedMarks.keys) {
        double obtained = report.subjectObtainedMarks[subjectId]!;
        double total = report.subjectTotalMarks[subjectId]!;
        report.subjectPercentage[subjectId] = total > 0 ? (obtained / total) * 100 : 0;
        report.grandObtainedMarks += obtained;
        report.grandTotalMarks += total;
      }
      if (report.grandTotalMarks > 0) {
        report.overallPercentage = (report.grandObtainedMarks / report.grandTotalMarks) * 100;
      }
    }

    final sortedReports = studentReportMap.values.toList();
    sortedReports.sort((a, b) => b.overallPercentage.compareTo(a.overallPercentage));

    return {'subjects': subjects, 'rankedStudents': sortedReports};
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();
    String reportTitle = sessionType == 'Monthly'
        ? "Monthly Report (${DateFormat('MMM yyyy').format(selectedMonth!)})"
        : "Overall Session Report";

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: Text(className, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF4F46E5)),
            onPressed: () => _showExportDialog(context, db, reportTitle),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportHeader(reportTitle),
          _buildLegendBar(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _getProcessedReportData(db),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (!snapshot.hasData || snapshot.data!['rankedStudents'].isEmpty) {
                    return _buildEmptyState();
                  }

                  final subjects = snapshot.data!['subjects'] as List<QueryDocumentSnapshot>;
                  final rankedStudents = snapshot.data!['rankedStudents'] as List<StudentFullReport>;

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: _buildConsolidatedTable(context, subjects, rankedStudents, reportTitle),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildConsolidatedTable(BuildContext context, List<QueryDocumentSnapshot> subjects, List<StudentFullReport> rankedStudents, String reportTitle) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: DataTable(
          showCheckboxColumn: false, // 👈 Dabba (Checkbox) khatam kar diya
          headingRowHeight: 56,
          dataRowHeight: 52,
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF9FAFB)),
          headingTextStyle: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4B5563), fontSize: 12),
          columns: [
            const DataColumn(label: Text('RANK')),
            const DataColumn(label: Text('ROLL #')),
            const DataColumn(label: Text('STUDENT NAME')),
            ...subjects.map((s) => DataColumn(label: Text(s['name'].toString().toUpperCase()))),
            const DataColumn(label: Text('GRAND TOTAL')),
            const DataColumn(label: Text('RESULT %')),
          ],
          rows: rankedStudents.asMap().entries.map((entry) {
            int rank = entry.key + 1;
            StudentFullReport student = entry.value;
            Color rowColor = _getRowColor(rank, student.overallPercentage);

            return DataRow(
              color: WidgetStateProperty.all(rowColor),
              onSelectChanged: (bool? selected) {
                if (selected != null && selected) {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => StudentIndividualResultCard(
                      student: student,
                      subjects: subjects,
                      reportTitle: reportTitle,
                    ),
                  ));
                }
              },
              cells: [
                DataCell(_buildRankCell(rank)),
                DataCell(Text(student.rollNumber, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4F46E5)))),
                DataCell(Text(student.studentName, style: TextStyle(fontWeight: rank <= 3 ? FontWeight.w900 : FontWeight.w700))),
                ...subjects.map((subject) {
                  double obtained = student.subjectObtainedMarks[subject.id] ?? 0;
                  double total = student.subjectTotalMarks[subject.id] ?? 0;
                  return DataCell(Text("${obtained.toStringAsFixed(0)} / ${total.toStringAsFixed(0)}", style: const TextStyle(fontSize: 12)));
                }),
                DataCell(Text("${student.grandObtainedMarks.toStringAsFixed(0)} / ${student.grandTotalMarks.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(_buildPercentageBadge(student.overallPercentage)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- HELPER UI WIDGETS ---

  Widget _buildReportHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("CONSOLIDATED ANALYTICS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF), letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
        ],
      ),
    );
  }

  Widget _buildLegendBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.withOpacity(0.1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _legendItem("🥇", "1st", Colors.amber),
          _legendItem("🥈", "2nd", Colors.blueGrey.shade300),
          _legendItem("🥉", "3rd", const Color(0xFFCD7F32)),
          _legendItem("🔴", "<40%", Colors.redAccent),
        ],
      ),
    );
  }

  Widget _legendItem(String emoji, String text, Color color) {
    return Row(children: [Text(emoji, style: const TextStyle(fontSize: 14)), const SizedBox(width: 4), Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11))]);
  }

  Widget _buildRankCell(int rank) {
    if (rank <= 3) {
      Color color = rank == 1 ? Colors.amber : (rank == 2 ? Colors.blueGrey.shade300 : const Color(0xFFCD7F32));
      return Container(
        width: 28, height: 28,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(child: Text("$rank", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12))),
      );
    }
    return Text("$rank", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey));
  }

  Widget _buildPercentageBadge(double percentage) {
    Color color = percentage >= 80 ? const Color(0xFF10B981) : (percentage >= 40 ? const Color(0xFF4F46E5) : Colors.redAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.2))),
      child: Text("${percentage.toStringAsFixed(1)}%", style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12)),
    );
  }

  Color _getRowColor(int rank, double percentage) {
    if (rank == 1) return const Color(0xFFFEF3C7).withOpacity(0.3);
    if (rank == 2) return const Color(0xFFF3F4F6).withOpacity(0.5);
    if (rank == 3) return const Color(0xFFFFEDD5).withOpacity(0.3);
    if (percentage < 40 && percentage > 0) return Colors.red.withOpacity(0.05);
    return Colors.white;
  }

  void _showExportDialog(BuildContext context, DatabaseService db, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("EXPORT REPORT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 24),
            _buildExportOption(context, Icons.picture_as_pdf_rounded, "Export as PDF", Colors.redAccent, () => _exportPDF(context, db, title)),
            const SizedBox(height: 12),
            _buildExportOption(context, Icons.table_chart_rounded, "Export as Excel", Colors.green, () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }

  void _exportPDF(BuildContext context, DatabaseService db, String title) async {
    Navigator.pop(context);
    try {
      final reportData = await _getProcessedReportData(db);
      await ReportService.generateAndSharePdf(reportData['rankedStudents'], reportData['subjects'], title, context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.indigo.shade50),
          const SizedBox(height: 16),
          const Text("No student performance data found", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}