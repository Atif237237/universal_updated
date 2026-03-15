import 'package:cloud_firestore/cloud_firestore.dart';

class FeeModel {
  final String id;
  final String studentId;
  final String studentName; // ADD THIS
  final String classId;
  final double amountPaid;
  final String feeMonth;
  final Timestamp paymentDate;

  FeeModel({
    required this.id,
    required this.studentId,
    required this.studentName, // ADD THIS
    required this.classId,
    required this.amountPaid,
    required this.feeMonth,
    required this.paymentDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName, // ADD THIS
      'classId': classId,
      'amountPaid': amountPaid,
      'feeMonth': feeMonth,
      'paymentDate': paymentDate,
    };
  }
}
