import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/services/database_service.dart';
import 'package:universal_science_academy/features/teacher_panel/presentation/screens/test_result_detail_screen.dart';
import 'admin_class_report_screen.dart';

class AdminSubjectTestListScreen extends StatelessWidget {
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;

  const AdminSubjectTestListScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();

    return Scaffold(
      backgroundColor: AppTheme.appBackground, // #F8F4EC
      appBar: AppBar(
        title: Text(subjectName, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.getResultsForSubjectStream(subjectId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final allResults = snapshot.data!.docs;
          final Map<String, List<QueryDocumentSnapshot>> uniqueTests = {};
          
          for (var result in allResults) {
            var data = result.data() as Map<String, dynamic>;
            if (data['sessionType'] == 'Test Session') {
              String testId = data.containsKey('testId')
                  ? result['testId']
                  : "legacy_${result['testName']}";
              uniqueTests.putIfAbsent(testId, () => []).add(result);
            }
          }

          final sessionTests = uniqueTests.entries.toList();

          if (sessionTests.isEmpty) return _buildEmptyState();

          return Column(
            children: [
              _buildSectionHeader("AVAILABLE TESTS"),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: sessionTests.length,
                  itemBuilder: (context, index) {
                    var testEntry = sessionTests[index];
                    var firstResult = testEntry.value.first;
                    String testName = firstResult['testName'];
                    DateTime testDate = (firstResult['testDate'] as Timestamp).toDate();

                    return _buildTestCard(context, testName, testDate, testEntry.value);
                  },
                ),
              ),
              
              // --- CONSOLIDATED REPORT ACTION ---
              _buildBottomAction(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF), letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildTestCard(BuildContext context, String name, DateTime date, List<QueryDocumentSnapshot> results) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => TestResultDetailScreen(testName: name, testResults: results),
        )),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.assignment_rounded, color: Color(0xFF4F46E5), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937), fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(DateFormat('dd MMMM, yyyy').format(date), style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: AppTheme.appBackground,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
          boxShadow: [
            BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => AdminClassReportScreen(classId: classId, className: className, sessionType: 'Test Session'),
          )),
          icon: const Icon(Icons.bar_chart_rounded, color: Colors.white),
          label: const Text("VIEW FULL REPORT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 64, color: Colors.indigo.shade100),
          const SizedBox(height: 16),
          const Text("No tests found for this subject", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        ],
      ),
    );
  }
}