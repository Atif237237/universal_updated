import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/services/database_service.dart';

class DailyAttendanceReportScreen extends StatelessWidget {
  final String classId;
  final String className;
  final DateTime selectedMonth;

  const DailyAttendanceReportScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.selectedMonth,
  });

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();
    
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
          _buildPeriodInfo(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: db.getAttendanceForClassInMonth(classId, selectedMonth),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final attendanceDocs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: attendanceDocs.length,
                  itemBuilder: (context, index) {
                    return _buildDailyAttendanceCard(context, attendanceDocs[index], db);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "ATTENDANCE LOGS",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF), letterSpacing: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyAttendanceCard(BuildContext context, DocumentSnapshot doc, DatabaseService db) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['date'] as Timestamp).toDate();
    final Map<String, dynamic> studentStatus = data['studentStatus'];

    final present = studentStatus.values.where((s) => s == 'Present').length;
    final absent = studentStatus.values.where((s) => s == 'Absent').length;
    final total = studentStatus.length;

    final absentStudentIds = studentStatus.entries
        .where((entry) => entry.value == 'Absent')
        .map((entry) => entry.key)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF4F46E5), size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  DateFormat('EEEE, MMM d').format(date),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactStat("TOTAL", total.toString(), Colors.grey.shade600),
                _buildCompactStat("PRESENT", present.toString(), const Color(0xFF10B981)),
                _buildCompactStat("ABSENT", absent.toString(), Colors.redAccent),
              ],
            ),
            if (absent > 0) ...[
              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 16),
              const Text("ABSENTEES LIST", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF), letterSpacing: 1)),
              const SizedBox(height: 12),
              _buildAbsenteesList(db, absentStudentIds),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAbsenteesList(DatabaseService db, List<String> ids) {
    return FutureBuilder<List<DocumentSnapshot>>(
      future: db.getStudentsByIds(ids),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator(minHeight: 2);
        
        return Column(
          children: snapshot.data!.map((studentDoc) {
            final data = studentDoc.data() as Map<String, dynamic>?;
            if (data == null) return const SizedBox();
            
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.redAccent.withOpacity(0.1), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_off_rounded, color: Colors.redAccent, size: 14),
                  const SizedBox(width: 10),
                  Text(data['name'] ?? "Unknown", style: const TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  Text("Roll: ${data['rollNumber']}", style: TextStyle(color: Colors.redAccent.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded, size: 64, color: Colors.indigo.shade100),
          const SizedBox(height: 16),
          const Text("No records for this month", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        ],
      ),
    );
  }
}