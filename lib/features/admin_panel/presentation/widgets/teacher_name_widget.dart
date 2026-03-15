import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:universal_science_academy/core/services/database_service.dart';

class TeacherNameWidget extends StatelessWidget {
  final String teacherId;
  const TeacherNameWidget({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    final DatabaseService databaseService = DatabaseService();

    return FutureBuilder<DocumentSnapshot>(
      future: databaseService.getTeacherById(teacherId),
      builder: (context, snapshot) {
        // Show a loading indicator while fetching data
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading teacher...");
        }
        // Show an error message if something goes wrong
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Text(
            "Unknown Teacher",
            style: TextStyle(color: Colors.red),
          );
        }

        // If data is fetched successfully, show the teacher's name
        var teacherData = snapshot.data!.data() as Map<String, dynamic>;
        return Text("Teacher: ${teacherData['name'] ?? 'N/A'}");
      },
    );
  }
}
