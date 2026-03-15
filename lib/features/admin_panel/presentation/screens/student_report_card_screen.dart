import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/core/services/database_service.dart';

// Helper class to hold subject-wise results
class SubjectResult {
  final String subjectName;
  double totalMarks = 0;
  double obtainedMarks = 0;
  double percentage = 0;

  SubjectResult({required this.subjectName});

  void calculatePercentage() {
    if (totalMarks > 0) {
      percentage = (obtainedMarks / totalMarks) * 100;
    }
  }
}

class StudentReportCardScreen extends StatelessWidget {
  final String classId;
  final String studentId;
  final String studentName;
  final String sessionType;
  final DateTime? selectedMonth;

  const StudentReportCardScreen({
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.sessionType,
    this.selectedMonth,
  });

  // This is the core logic that processes the data for one student
  Future<Map<String, dynamic>> _getReportCardData(DatabaseService db) async {
    final reportData = await db.getConsolidatedReportForClass(classId);
    final List<QueryDocumentSnapshot> subjects = reportData['subjects'];
    final List<QueryDocumentSnapshot> allResults = reportData['results'];

    // --- THIS IS THE FIX ---
    // Filter results for the selected student and session
    final studentResults = allResults.where((result) {
      var data = result.data() as Map<String, dynamic>;
      if (data['studentId'] != studentId ||
          data['sessionType'] != sessionType) {
        return false;
      }
      if (sessionType == 'Monthly' && selectedMonth != null) {
        if (!data.containsKey('monthFor') || data['monthFor'] == null) {
          return false;
        }
        DateTime resultMonth = (data['monthFor'] as Timestamp).toDate();
        return resultMonth.year == selectedMonth!.year &&
            resultMonth.month == selectedMonth!.month;
      }
      return true;
    }).toList();
    // -------------------------

    // Consolidate results by subject
    Map<String, SubjectResult> subjectMap = {};
    for (var subjectDoc in subjects) {
      subjectMap[subjectDoc.id] = SubjectResult(
        subjectName: subjectDoc['name'],
      );
    }

    for (var resultDoc in studentResults) {
      var data = resultDoc.data() as Map<String, dynamic>;
      String subjectId = data['subjectId'];
      if (subjectMap.containsKey(subjectId)) {
        subjectMap[subjectId]!.obtainedMarks += (data['marksObtained'] as num)
            .toDouble();
        subjectMap[subjectId]!.totalMarks += (data['totalMarks'] as num)
            .toDouble();
      }
    }

    // Calculate percentages and grand totals
    double grandTotalMarks = 0;
    double grandObtainedMarks = 0;
    for (var subjectResult in subjectMap.values) {
      subjectResult.calculatePercentage();
      grandTotalMarks += subjectResult.totalMarks;
      grandObtainedMarks += subjectResult.obtainedMarks;
    }

    double overallPercentage = grandTotalMarks > 0
        ? (grandObtainedMarks / grandTotalMarks) * 100
        : 0;

    return {
      'subjectResults': subjectMap.values
          .where((s) => s.totalMarks > 0)
          .toList(), // Only show subjects with marks
      'grandTotal': grandTotalMarks,
      'grandObtained': grandObtainedMarks,
      'overallPercentage': overallPercentage,
    };
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();
    String reportTitle = sessionType == 'Monthly'
        ? "Report for ${DateFormat('MMMM yyyy').format(selectedMonth!)}"
        : "Overall Test Session Report";

    return Scaffold(
      appBar: AppBar(title: Text(studentName)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _getReportCardData(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Could not generate report."));
          }

          final report = snapshot.data!;
          final List<SubjectResult> subjectResults = report['subjectResults'];

          if (subjectResults.isEmpty) {
            return const Center(
              child: Text(
                "No results found for this student in the selected session.",
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(reportTitle, style: Theme.of(context).textTheme.titleLarge),
              const Divider(height: 24),
              DataTable(
                columns: const [
                  DataColumn(label: Text('Subject')),
                  DataColumn(label: Text('Obtained')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('%')),
                ],
                rows: subjectResults
                    .map(
                      (result) => DataRow(
                        cells: [
                          DataCell(Text(result.subjectName)),
                          DataCell(
                            Text(result.obtainedMarks.toStringAsFixed(1)),
                          ),
                          DataCell(Text(result.totalMarks.toStringAsFixed(1))),
                          DataCell(
                            Text('${result.percentage.toStringAsFixed(2)}%'),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
              const Divider(height: 32),
              _buildGrandTotalCard(context, report),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGrandTotalCard(
    BuildContext context,
    Map<String, dynamic> report,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Overall Performance",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  "Obtained Marks",
                  report['grandObtained'].toStringAsFixed(1),
                ),
                _buildStatItem(
                  "Total Marks",
                  report['grandTotal'].toStringAsFixed(1),
                ),
                _buildStatItem(
                  "Percentage",
                  "${report['overallPercentage'].toStringAsFixed(2)}%",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
