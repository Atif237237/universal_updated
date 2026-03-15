import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/core/services/database_service.dart';
import 'student_report_card_screen.dart';

// Helper class to hold the final calculated data for each student
class StudentOverallResult {
  final String studentId;
  final String studentName;
  double totalMarks = 0;
  double obtainedMarks = 0;
  double percentage = 0;

  StudentOverallResult({required this.studentId, required this.studentName});

  void calculatePercentage() {
    if (totalMarks > 0) {
      percentage = (obtainedMarks / totalMarks) * 100;
    }
  }
}

class ClassRankingScreen extends StatelessWidget {
  final String classId;
  final String className;
  final String sessionType;
  final DateTime? selectedMonth;

  const ClassRankingScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.sessionType,
    this.selectedMonth,
  });

  // This is the core logic that processes all the data
  Future<List<StudentOverallResult>> _calculateRanks(DatabaseService db) async {
    // 1. Fetch all data for the class in one go
    final reportData = await db.getConsolidatedReportForClass(classId);
    final List<QueryDocumentSnapshot> students = reportData['students'];
    final List<QueryDocumentSnapshot> allResults = reportData['results'];

    // --- THIS IS THE FIX ---
    // 2. Filter the results based on the session type and month
    final filteredResults = allResults.where((result) {
      var data = result.data() as Map<String, dynamic>;
      // Skip if session type doesn't match
      if (data['sessionType'] != sessionType) {
        return false;
      }
      // For monthly reports, also check if the month matches
      if (sessionType == 'Monthly' && selectedMonth != null) {
        // Handle old records that might not have 'monthFor'
        if (!data.containsKey('monthFor') || data['monthFor'] == null) {
          return false;
        }

        DateTime resultMonth = (data['monthFor'] as Timestamp).toDate();
        return resultMonth.year == selectedMonth!.year &&
            resultMonth.month == selectedMonth!.month;
      }
      return true; // For 'Test Session', include all
    }).toList();
    // -------------------------

    // 3. Create a map to store each student's consolidated result
    Map<String, StudentOverallResult> consolidatedMap = {};
    for (var studentDoc in students) {
      consolidatedMap[studentDoc.id] = StudentOverallResult(
        studentId: studentDoc.id,
        studentName: studentDoc['name'],
      );
    }

    // 4. Loop through the FILTERED results and add marks
    for (var resultDoc in filteredResults) {
      var data = resultDoc.data() as Map<String, dynamic>;
      String studentId = data['studentId'];

      if (consolidatedMap.containsKey(studentId)) {
        consolidatedMap[studentId]!.obtainedMarks +=
            (data['marksObtained'] as num).toDouble();
        consolidatedMap[studentId]!.totalMarks += (data['totalMarks'] as num)
            .toDouble();
      }
    }

    // 5. Calculate the final percentage and sort
    final studentList = consolidatedMap.values.toList();
    for (var student in studentList) {
      student.calculatePercentage();
    }
    studentList.sort((a, b) => b.percentage.compareTo(a.percentage));

    return studentList;
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();
    String reportTitle = sessionType == 'Monthly'
        ? "$className (${DateFormat('MMMM yyyy').format(selectedMonth!)})"
        : "$className (Test Session)";

    return Scaffold(
      appBar: AppBar(title: Text(reportTitle)),
      body: FutureBuilder<List<StudentOverallResult>>(
        future: _calculateRanks(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          // Show message if no results are found for THIS specific filter
          if (!snapshot.hasData ||
              snapshot.data!.where((s) => s.totalMarks > 0).isEmpty) {
            return const Center(
              child: Text("No test results found for this selection."),
            );
          }

          final rankedStudents = snapshot.data!;

          return ListView.builder(
            itemCount: rankedStudents.length,
            itemBuilder: (context, index) {
              final studentResult = rankedStudents[index];
              final rank = index + 1;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text(rank.toString())),
                  title: Text(
                    studentResult.studentName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Overall Percentage: ${studentResult.percentage.toStringAsFixed(2)}%",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => StudentReportCardScreen(
                          classId: classId,
                          studentId: studentResult.studentId,
                          studentName: studentResult.studentName,
                          sessionType: sessionType,
                          selectedMonth: selectedMonth,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
