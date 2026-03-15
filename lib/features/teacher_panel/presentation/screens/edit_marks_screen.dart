import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/services/database_service.dart';

class EditMarksScreen extends StatefulWidget {
  final List<QueryDocumentSnapshot> testResults;
  const EditMarksScreen({super.key, required this.testResults});

  @override
  State<EditMarksScreen> createState() => _EditMarksScreenState();
}

class _EditMarksScreenState extends State<EditMarksScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Map<String, TextEditingController> _marksControllers;
  late String _testName;
  late double _totalMarks;
  bool _isSaving = false;

  late List<QueryDocumentSnapshot> _sortedTestResults;

  @override
  void initState() {
    super.initState();
    _marksControllers = {};
    _sortedTestResults = List.from(widget.testResults); 
    
    _testName = widget.testResults.first['testName'];
    _totalMarks = (widget.testResults.first['totalMarks'] as num).toDouble();

    for (var result in widget.testResults) {
      _marksControllers[result.id] = TextEditingController(
        text: (result['marksObtained'] as num).toString(),
      );
    }
    
    _sortResultsByRollNumber();
  }

  Future<void> _sortResultsByRollNumber() async {
    Map<String, String> studentRollNumbers = {};
    final studentIds = widget.testResults
        .map((doc) => doc['studentId'].toString())
        .toSet()
        .toList();

    final studentDocs = await _databaseService.getStudentsByIds(studentIds);

    for (var doc in studentDocs) {
      studentRollNumbers[doc.id] = doc['rollNumber'];
    }

    _sortedTestResults.sort((a, b) {
      final rollA = studentRollNumbers[a['studentId']] ?? '0';
      final rollB = studentRollNumbers[b['studentId']] ?? '0';
      try {
        return int.parse(rollA).compareTo(int.parse(rollB));
      } catch (e) {
        return rollA.compareTo(rollB);
      }
    });

    if (mounted) setState(() {});
  }

  void _updateMarks() async {
    HapticFeedback.mediumImpact();
    Map<String, double> updatedMarks = {};
    
    for (var entry in _marksControllers.entries) {
      final marksObtained = double.tryParse(entry.value.text) ?? 0.0;
      if (marksObtained > _totalMarks) {
        _showSnackBar("Marks cannot exceed total (($_totalMarks))", isError: true);
        return;
      }
      updatedMarks[entry.key] = marksObtained;
    }

    setState(() => _isSaving = true);
    try {
      await _databaseService.updateTestResults(updatedMarks);
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar("Marks updated successfully!", isError: false);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(20),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: Text("Edit Results", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTestSummaryHeader(),
          _buildSectionLabel("STUDENT LIST (SORTED BY ROLL NO)"),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              itemCount: _sortedTestResults.length,
              itemBuilder: (context, index) {
                var result = _sortedTestResults[index];
                return _buildEditMarkTile(result);
              },
            ),
          ),
          _buildSaveAction(),
        ],
      ),
    );
  }

  Widget _buildTestSummaryHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937), // Dark Slate
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.edit_document, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_testName, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                Text("Total Marks: $_totalMarks", style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditMarkTile(QueryDocumentSnapshot result) {
    final studentId = result.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
          child: Text(result['studentName'][0], style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
        ),
        title: Text(result['studentName'], style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700)),
        trailing: SizedBox(
          width: 80,
          child: TextField(
            controller: _marksControllers[studentId],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4F46E5)),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              hintText: "0.0",
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveAction() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _updateMarks,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isSaving
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : const Text("UPDATE ALL RECORDS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Align(alignment: Alignment.centerLeft, child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF9CA3AF), letterSpacing: 1.5))),
    );
  }
}