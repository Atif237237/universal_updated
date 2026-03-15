import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:universal_science_academy/features/admin_panel/presentation/screens/admin_subject_report_screen.dart';

class SubjectReportOptionsScreen extends StatelessWidget {
  final String classId;
  final String className;
  final String subjectId;
  final String subjectName;

  const SubjectReportOptionsScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subjectName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Monthly Test Report Card ---
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text("Monthly Test Report"),
                subtitle: const Text("View results for a specific month"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  // Show month picker
                  final selectedMonth = await showMonthPicker(
                    context: context,
                    initialDate: DateTime.now(),
                  );

                  if (selectedMonth != null && context.mounted) {
                    // Navigate to the final report screen with the selected month
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminSubjectReportScreen(
                          classId: classId,
                          className: className,
                          subjectId: subjectId,
                          subjectName: subjectName,
                          sessionType: 'Monthly',
                          selectedMonth: selectedMonth,
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            // --- Test Session Report Card ---
            Card(
              child: ListTile(
                leading: const Icon(Icons.assessment_outlined),
                title: const Text("Overall Test Session Report"),
                subtitle: const Text("View consolidated results for all tests"),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to the final report screen for the whole session
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AdminSubjectReportScreen(
                        classId: classId,
                        className: className,
                        subjectId: subjectId,
                        subjectName: subjectName,
                        sessionType: 'Test Session',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
