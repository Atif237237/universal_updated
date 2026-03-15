import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/core/services/database_service.dart';

// A helper class to hold the calculated data for each student
class StudentConsolidatedResult {
  final String studentId;
  final String studentName;
  double totalMarks = 0;
  double obtainedMarks = 0;
  double percentage = 0;

  StudentConsolidatedResult({
    required this.studentId,
    required this.studentName,
  });

  void calculatePercentage() {
    if (totalMarks > 0) {
      percentage = (obtainedMarks / totalMarks) * 100;
    }
  }
}

class AdminSubjectReportScreen extends StatelessWidget {
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;
  final String sessionType;
  final DateTime? selectedMonth;

  const AdminSubjectReportScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
    required this.sessionType,
    this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();
    String reportTitle = sessionType == 'Monthly'
        ? "$subjectName (${DateFormat('MMMM yyyy').format(selectedMonth!)})"
        : "$subjectName (Overall Test Session)";

    return Scaffold(
      appBar: AppBar(title: Text(reportTitle)),
      body: FutureBuilder<List<StudentConsolidatedResult>>(
        future: _getConsolidatedResults(db),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No test results found for this selection."),
            );
          }

          final studentResults = snapshot.data!;

          // Sort the final list by percentage (highest first)
          studentResults.sort((a, b) => b.percentage.compareTo(a.percentage));

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: DataTable(
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Rank')),
                  DataColumn(label: Text('Student Name')),
                  DataColumn(label: Text('Obtained Marks')),
                  DataColumn(label: Text('Total Marks')),
                  DataColumn(label: Text('Percentage')),
                ],
                rows: studentResults.asMap().entries.map((entry) {
                  int rank = entry.key + 1;
                  var result = entry.value;

                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (rank == 1) return Colors.green.withOpacity(0.1);
                      if (rank == 2) return Colors.blue.withOpacity(0.1);
                      if (rank == 3) return Colors.orange.withOpacity(0.1);
                      return null;
                    }),
                    cells: [
                      DataCell(Text('$rank')),
                      DataCell(Text(result.studentName)),
                      DataCell(Text(result.obtainedMarks.toStringAsFixed(1))),
                      DataCell(Text(result.totalMarks.toStringAsFixed(1))),
                      DataCell(
                        Text('${result.percentage.toStringAsFixed(2)}%'),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  // This is the core logic that processes the data
  Future<List<StudentConsolidatedResult>> _getConsolidatedResults(
    DatabaseService db,
  ) async {
    final rawResults = await db.getTestResultsForAdmin(
      subjectId: subjectId,
      sessionType: sessionType,
      month: selectedMonth,
    );

    // A map to hold the consolidated results for each student
    Map<String, StudentConsolidatedResult> consolidatedMap = {};

    for (var doc in rawResults) {
      var data = doc.data() as Map<String, dynamic>;
      String studentId = data['studentId'];
      String studentName = data['studentName'];

      // If we haven't seen this student before, create a new entry
      consolidatedMap.putIfAbsent(
        studentId,
        () => StudentConsolidatedResult(
          studentId: studentId,
          studentName: studentName,
        ),
      );

      // Add the marks to the student's total
      consolidatedMap[studentId]!.obtainedMarks +=
          (data['marksObtained'] as num).toDouble();
      consolidatedMap[studentId]!.totalMarks += (data['totalMarks'] as num)
          .toDouble();
    }

    // Calculate the percentage for each student
    for (var result in consolidatedMap.values) {
      result.calculatePercentage();
    }

    return consolidatedMap.values.toList();
  }
}

// is ko bi update kro or roll number be add kro