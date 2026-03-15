import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/services/database_service.dart';

class StudentFeeStatusScreen extends StatefulWidget {
  final String classId;
  final String className;
  final DateTime selectedMonth;

  const StudentFeeStatusScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.selectedMonth,
  });

  @override
  State<StudentFeeStatusScreen> createState() => _StudentFeeStatusScreenState();
}

class _StudentFeeStatusScreenState extends State<StudentFeeStatusScreen> {
  final DatabaseService db = DatabaseService();
  String _selectedStatusFilter = 'All';
  String _selectedGroupFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(widget.className, 
              style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1F2937), fontSize: 18)),
            Text(DateFormat('MMMM yyyy').format(widget.selectedMonth), 
              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: db.getStudentFeeStatusForClass(widget.classId, widget.selectedMonth),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyState();

          var allStudents = snapshot.data!;
          
          // Logic for filters
          final groupFiltered = allStudents.where((s) => _selectedGroupFilter == 'All' || s['studentGroup'] == _selectedGroupFilter).toList();
          final fullyFiltered = groupFiltered.where((s) {
            if (_selectedStatusFilter == 'Paid') return s['hasPaid'];
            if (_selectedStatusFilter == 'Unpaid') return !s['hasPaid'];
            return true;
          }).toList();

          // Quick Stats calculation
          int paidCount = groupFiltered.where((s) => s['hasPaid']).length;
          double totalCol = groupFiltered.where((s) => s['hasPaid']).fold(0.0, (sum, s) => sum + (s['amountPaid'] ?? 0));

          return Column(
            children: [
              // --- 1. CONSOLIDATED STATS CARD ---
              _buildModernStatsHeader(groupFiltered.length, paidCount, totalCol),

              // --- 2. MULTI-LEVEL FILTERS ---
              _buildFilterSection(allStudents, groupFiltered.length, paidCount),

              const SizedBox(height: 8),

              // --- 3. STUDENT LIST ---
              Expanded(
                child: fullyFiltered.isEmpty 
                  ? _buildEmptyState(message: "No students match these filters")
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: fullyFiltered.length,
                      itemBuilder: (context, index) => _buildStudentFeeCard(fullyFiltered[index]),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernStatsHeader(int total, int paid, double collection) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatColumn("Students", "$total", const Color(0xFF4F46E5)),
          _buildDivider(),
          _buildStatColumn("Paid", "$paid", const Color(0xFF10B981)),
          _buildDivider(),
          _buildStatColumn("Collection", "Rs. ${NumberFormat('#,##0').format(collection)}", const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildDivider() => Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.2));

  Widget _buildFilterSection(List<Map<String, dynamic>> all, int total, int paid) {
    final uniqueGroups = <String>{'All'};
    for (var s in all) if (s['studentGroup'] != null) uniqueGroups.add(s['studentGroup']);

    return Column(
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _statusChip('All', _selectedStatusFilter == 'All', total, const Color(0xFF4F46E5)),
              _statusChip('Paid', _selectedStatusFilter == 'Paid', paid, const Color(0xFF10B981)),
              _statusChip('Unpaid', _selectedStatusFilter == 'Unpaid', total - paid, Colors.redAccent),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 35,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: uniqueGroups.map((g) => _groupChip(g)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(String label, bool isSelected, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text("$label ($count)"),
        selected: isSelected,
        onSelected: (val) => setState(() => _selectedStatusFilter = label),
        backgroundColor: Colors.white,
        selectedColor: color.withOpacity(0.1),
        labelStyle: TextStyle(color: isSelected ? color : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? color : Colors.grey.withOpacity(0.2))),
        showCheckmark: false,
      ),
    );
  }

  Widget _groupChip(String group) {
    bool isSelected = _selectedGroupFilter == group;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(group),
        selected: isSelected,
        onSelected: (val) => setState(() => _selectedGroupFilter = group),
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFF1F2937).withOpacity(0.1),
        labelStyle: TextStyle(color: isSelected ? const Color(0xFF1F2937) : Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? const Color(0xFF1F2937) : Colors.transparent)),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildStudentFeeCard(Map<String, dynamic> data) {
    bool paid = data['hasPaid'];
    Color statusColor = paid ? const Color(0xFF10B981) : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(paid ? Icons.verified_rounded : Icons.info_outline_rounded, color: statusColor, size: 22),
        ),
        title: Text(data['studentName'] ?? 'Student', 
          style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937), fontSize: 15)),
        subtitle: Text("Group: ${data['studentGroup']}", 
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (paid) 
              Text("Rs. ${data['amountPaid']}", 
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1F2937), fontSize: 14))
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text("UNPAID", style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(height: 4),
            Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({String message = "No records found"}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_rounded, size: 64, color: Colors.indigo.shade50),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}