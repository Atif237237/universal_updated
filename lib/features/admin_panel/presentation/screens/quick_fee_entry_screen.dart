import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/models/fee_model.dart';
import 'package:universal_science_academy/core/services/database_service.dart';

class QuickFeeEntryScreen extends StatefulWidget {
  const QuickFeeEntryScreen({super.key});

  @override
  State<QuickFeeEntryScreen> createState() => _QuickFeeEntryScreenState();
}

class _QuickFeeEntryScreenState extends State<QuickFeeEntryScreen> {
  final DatabaseService _db = DatabaseService();

  String? _selectedClassId;
  DocumentSnapshot? _selectedStudent;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  DateTime _selectedMonth = DateTime.now();
  bool _isLoading = false;
  String _selectedGroupFilter = 'All';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _recordPayment(DocumentSnapshot studentDoc) {
    if (_amountController.text.isEmpty) return;

    setState(() => _isLoading = true);

    final payment = FeeModel(
      id: '',
      studentId: studentDoc.id,
      studentName: studentDoc['name'],
      classId: studentDoc['classId'],
      amountPaid: double.tryParse(_amountController.text) ?? 0.0,
      feeMonth: DateFormat('MMMM yyyy').format(_selectedMonth),
      paymentDate: Timestamp.now(),
    );

    _db.recordFeePayment(payment).then((_) {
      _showSnackBar("Fee recorded for ${studentDoc['name']}", isError: false);
      setState(() {
        _searchController.clear();
        _amountController.clear();
        _searchQuery = "";
      });
    }).catchError((e) {
      _showSnackBar("Error: $e", isError: true);
    }).whenComplete(() {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground, // #F8F4EC
      appBar: AppBar(
        title: const Text("Quick Fee Entry"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- STEP 1: CLASS SELECTION ---
          _buildStepLabel("STEP 1: SELECT CLASS"),
          _buildClassDropdown(),

          if (_selectedClassId != null) ...[
            // --- STEP 2: SEARCH STUDENT ---
            _buildStepLabel("STEP 2: FIND STUDENT"),
            _buildSearchField(),

            // --- STUDENT LIST WITH FILTERS ---
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.getAllStudentsStream(query: _searchQuery, classId: _selectedClassId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState("No students found");
                  }

                  final allStudents = snapshot.data!.docs;
                  final uniqueGroups = <String>{'All'};
                  for (var s in allStudents) uniqueGroups.add(s['studentGroup'] ?? 'N/A');

                  final filtered = allStudents.where((s) {
                    return _selectedGroupFilter == 'All' || s['studentGroup'] == _selectedGroupFilter;
                  }).toList();

                  return Column(
                    children: [
                      _buildGroupFilters(uniqueGroups),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                          physics: const BouncingScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildStudentTile(filtered[index]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ] else
            Expanded(child: _buildEmptyState("Select a class to start")),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF9CA3AF), letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<QuerySnapshot>(
        stream: _db.getClassesStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          var classes = snapshot.data!.docs;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedClassId,
                hint: const Text("Choose a class...", style: TextStyle(fontSize: 14)),
                isExpanded: true,
                items: classes.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['name']))).toList(),
                onChanged: (val) => setState(() {
                  _selectedClassId = val;
                  _searchController.clear();
                  _selectedGroupFilter = 'All';
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: "Type student name...",
            prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF4F46E5), size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupFilters(Set<String> groups) {
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: groups.map((g) {
          bool sel = _selectedGroupFilter == g;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(g),
              selected: sel,
              onSelected: (s) => setState(() => _selectedGroupFilter = g),
              backgroundColor: Colors.white,
              selectedColor: const Color(0xFF4F46E5).withOpacity(0.1),
              labelStyle: TextStyle(color: sel ? const Color(0xFF4F46E5) : Colors.grey, fontWeight: FontWeight.bold, fontSize: 11),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: sel ? const Color(0xFF4F46E5) : Colors.grey.withOpacity(0.2))),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStudentTile(DocumentSnapshot doc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
          child: Text(doc['rollNumber'] ?? '#', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        title: Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
        subtitle: Text("Group: ${doc['studentGroup'] ?? 'N/A'}", style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        onTap: () => _showPaymentDialog(doc),
      ),
    );
  }

  void _showPaymentDialog(DocumentSnapshot doc) {
    _amountController.clear();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text("Fee for ${doc['name']}", style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final p = await showMonthPicker(context: context, initialDate: _selectedMonth);
                  if (p != null) setDialogState(() => _selectedMonth = p);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withOpacity(0.1))),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFF4F46E5), size: 18),
                      const SizedBox(width: 12),
                      Text(DateFormat('MMMM yyyy').format(_selectedMonth), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Amount Paid (PKR)",
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () {
                _recordPayment(doc);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text("Save Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(child: Text(msg, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)));
  }
}