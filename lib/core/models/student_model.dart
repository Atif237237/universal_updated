import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String id;
  final String name;
  final String fatherName;
  final String rollNumber;
  final String classId;
  final Timestamp admissionDate;
  final String studentGroup;
  final String searchName;
  final String phoneNumber;

  StudentModel({
    required this.id,
    required this.name,
    required this.fatherName,
    required this.rollNumber,
    required this.classId,
    required this.admissionDate,
    required this.studentGroup,
    required this.searchName,
    required this.phoneNumber,
  });

  /// Convert to Map (for Firestore saving)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fatherName': fatherName,
      'rollNumber': rollNumber,
      'classId': classId,
      'admissionDate': admissionDate,
      'studentGroup': studentGroup,
      'searchName': searchName,
      'phoneNumber': phoneNumber,
    };
  }

  /// Create object from Firestore Map
  factory StudentModel.fromMap(Map<String, dynamic> map, String docId) {
    return StudentModel(
      id: docId,
      name: map['name'] ?? '',
      fatherName: map['fatherName'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      classId: map['classId'] ?? '',
      admissionDate: map['admissionDate'] ?? Timestamp.now(),
      studentGroup: map['studentGroup'] ?? '',
      searchName: map['searchName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }

  /// Create from Firestore DocumentSnapshot
  factory StudentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentModel.fromMap(data, doc.id);
  }

  /// Convert to JSON (optional if using APIs)
  Map<String, dynamic> toJson() => toMap();

  /// Create from JSON (optional)
  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel.fromMap(json, json['id'] ?? '');
  }

  /// CopyWith (for immutability & updates)
  StudentModel copyWith({
    String? id,
    String? name,
    String? fatherName,
    String? rollNumber,
    String? classId,
    Timestamp? admissionDate,
    String? studentGroup,
    String? searchName,
    String? phoneNumber,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fatherName: fatherName ?? this.fatherName,
      rollNumber: rollNumber ?? this.rollNumber,
      classId: classId ?? this.classId,
      admissionDate: admissionDate ?? this.admissionDate,
      studentGroup: studentGroup ?? this.studentGroup,
      searchName: searchName ?? this.searchName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
