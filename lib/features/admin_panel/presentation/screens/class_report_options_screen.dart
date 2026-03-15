import 'package:flutter/material.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'admin_class_report_screen.dart';
import 'admin_subject_selection_screen.dart';

class ClassReportOptionsScreen extends StatelessWidget {
  final String classId;
  final String className;

  const ClassReportOptionsScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground, // #F8F4EC
      appBar: AppBar(
        title: Text(className, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER SECTION ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "REPORT OPTIONS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Academic Selection",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // --- OPTIONS LIST ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildReportOptionCard(
                  context,
                  title: "Monthly Test Report",
                  subtitle: "Class-wide detailed monthly insights",
                  icon: Icons.calendar_month_rounded,
                  accentColor: const Color(0xFF4F46E5), // Indigo
                  onTap: () async {
                    final selectedMonth = await showMonthPicker(
                      context: context,
                      initialDate: DateTime.now(),
                    );
                    if (selectedMonth != null && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AdminClassReportScreen(
                            classId: classId,
                            className: className,
                            sessionType: 'Monthly',
                            selectedMonth: selectedMonth,
                          ),
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildReportOptionCard(
                  context,
                  title: "Subject-wise Performance",
                  subtitle: "Detailed metrics for specific subjects",
                  icon: Icons.analytics_rounded,
                  accentColor: const Color(0xFF8B5CF6), // Violet
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminSubjectSelectionScreen(
                          classId: classId,
                          className: className,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon Box with Soft Tint
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accentColor, size: 26),
              ),
              const SizedBox(width: 16),
              // Option Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade300,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}