import 'package:flutter/material.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/services/report_service.dart';
import 'admin_class_report_screen.dart'; 

class StudentIndividualResultCard extends StatelessWidget {
  final StudentFullReport student;
  final List<dynamic> subjects;
  final String reportTitle;

  const StudentIndividualResultCard({
    super.key,
    required this.student,
    required this.subjects,
    required this.reportTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground, 
      appBar: AppBar(
        title: const Text("Student Result Card"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_for_offline_rounded, color: Color(0xFF4F46E5)),
            onPressed: () => _exportIndividualPDF(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            _buildStudentIdentityHeader(),
            const SizedBox(height: 24),
            _buildSectionLabel("SUBJECT-WISE PERFORMANCE"),
            const SizedBox(height: 12),
            _buildSubjectResultsList(),
            const SizedBox(height: 24),
            _buildOverallSummaryCard(),
            const SizedBox(height: 40),
            
            // --- ACTION BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _exportIndividualPDF(context),
                icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white),
                label: const Text("GENERATE PDF REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- PDF GENERATION CALL ---
  Future<void> _exportIndividualPDF(BuildContext context) async {
    try {
      // Show loading feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Preparing Report for ${student.studentName}..."),
          backgroundColor: const Color(0xFF4F46E5),
        ),
      );

      // Call the NEW Individual PDF Method
      await ReportService.generateIndividualStudentCardPdf(
        student: student,
        subjects: subjects,
        reportTitle: reportTitle,
        context: context,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not generate PDF: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  // UI Helper methods (Same as you provided but cleaned up)
  Widget _buildStudentIdentityHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2), width: 2)),
            child: const CircleAvatar(
              radius: 35,
              backgroundColor: Color(0xFFF3F4F6),
              child: Icon(Icons.person_rounded, size: 40, color: Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.studentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildSmallInfoBadge("ROLL: ${student.rollNumber}"),
                    _buildSmallInfoBadge("ID: ${student.studentId.substring(0,5).toUpperCase()}"),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5))),
    );
  }

  Widget _buildSubjectResultsList() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.withOpacity(0.15))),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: subjects.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withOpacity(0.05)),
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final sId = subject.id;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Text(subject['name'], style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text("${(student.subjectObtainedMarks[sId] ?? 0).toStringAsFixed(1)} / ${(student.subjectTotalMarks[sId] ?? 0).toStringAsFixed(0)} Marks"),
            trailing: _buildPercentagePill(student.subjectPercentage[sId] ?? 0),
          );
        },
      ),
    );
  }

  Widget _buildPercentagePill(double percentage) {
    Color color = percentage >= 40 ? const Color(0xFF10B981) : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Text("${percentage.toStringAsFixed(1)}%", style: TextStyle(color: color, fontWeight: FontWeight.w900)),
    );
  }

  Widget _buildOverallSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Text("GRAND SUMMARY", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 2)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat("Obtained", student.grandObtainedMarks.toStringAsFixed(1)),
              Container(height: 30, width: 1, color: Colors.white24),
              _buildStat("Total", student.grandTotalMarks.toStringAsFixed(0)),
              Container(height: 30, width: 1, color: Colors.white24),
              _buildStat("% Age", "${student.overallPercentage.toStringAsFixed(1)}%"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String val) {
    return Column(children: [Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)), Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10))]);
  }

  Widget _buildSectionLabel(String label) {
    return Align(alignment: Alignment.centerLeft, child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF), letterSpacing: 1.5)));
  }
}