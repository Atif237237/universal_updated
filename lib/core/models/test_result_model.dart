import 'package:cloud_firestore/cloud_firestore.dart';

class TestResultModel {
  final String testName;
  final String sessionType; // 'Monthly' or 'Test Session'
  final Timestamp testDate;
  final double totalMarks;
  final double marksObtained;
  final String studentId;
  final String studentName;
  final String classId;
  final String subjectId;
  final String teacherId;
  final String testId; // Unique ID for the test
  final Timestamp? monthFor; // Optional, used for monthly tests
  TestResultModel({
    required this.testName,
    required this.sessionType,
    required this.testDate,
    required this.totalMarks,
    required this.marksObtained,
    required this.studentId,
    required this.studentName,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.testId,
    this.monthFor,
  });

  Map<String, dynamic> toMap() {
    return {
      'testName': testName,
      'sessionType': sessionType,
      'testDate': testDate,
      'totalMarks': totalMarks,
      'marksObtained': marksObtained,
      'studentId': studentId,
      'studentName': studentName,
      'classId': classId,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'testId': testId,
      // Save the unique ID for the test
      'monthFor': monthFor,
    };
  }
}
