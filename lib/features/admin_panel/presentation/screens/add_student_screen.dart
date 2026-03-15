import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/models/student_model.dart';
import 'package:universal_science_academy/core/services/database_service.dart';

class AddStudentScreen extends StatefulWidget {
  final String? initialSubjectName;
  final String? initialSubjectType;
  final String? classId;
  final String? className;

  const AddStudentScreen({
    this.initialSubjectName,
    this.initialSubjectType,
    super.key,
    this.classId,
    this.className,
  });

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _rollNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();

  DateTime? _selectedDate;
  String? _selectedClassId;
  String? _selectedClassName;
  String? _selectedGroup;
  bool _isLoading = false;
  List<String> _availableGroups = [];

  @override
  void initState() {
    super.initState();
    if (widget.classId != null) {
      _selectedClassId = widget.classId;
      _selectedClassName = widget.className;
      _updateGroupOptions(_selectedClassName);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _rollNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateGroupOptions(String? className) {
    if (className == null) {
      setState(() => _availableGroups = []);
      return;
    }
    String lowerClassName = className.toLowerCase();
    List<String> groups = [];

    if (lowerClassName.contains('11') ||
        lowerClassName.contains('12') ||
        lowerClassName.contains('fsc') ||
        lowerClassName.contains('ics')) {
      groups = ['FSC Pre-Medical', 'FSC Pre-Engineering', 'ICS'];
    } else if (lowerClassName.contains('9') || lowerClassName.contains('10')) {
      groups = ['Biology', 'Computer Science'];
    } else {
      groups = ['General'];
    }

    setState(() {
      _availableGroups = groups;
      _selectedGroup = groups.length == 1 ? groups.first : null;
    });
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      _showSnackBar("Please select an admission date.", isError: true);
      return;
    }
    if (_selectedGroup == null) {
      _showSnackBar("Please select a student group.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final isUnique = await _databaseService.isRollNumberUnique(_rollNumberController.text.trim());
      if (!isUnique && mounted) {
        _showSnackBar("Error: This Roll Number already exists.", isError: true);
        setState(() => _isLoading = false);
        return;
      }

      String studentName = _nameController.text.trim();
      StudentModel newStudent = StudentModel(
        id: '',
        name: studentName,
        fatherName: _fatherNameController.text.trim(),
        rollNumber: _rollNumberController.text.trim(),
        classId: _selectedClassId!,
        studentGroup: _selectedGroup!,
        admissionDate: Timestamp.fromDate(_selectedDate!),
        searchName: studentName.toLowerCase(),
        phoneNumber: _phoneController.text.trim(),
      );

      await _databaseService.addStudent(newStudent.toMap());
      _showSnackBar("Student Added Successfully!");
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) _showSnackBar("Failed to add student: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
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

  InputDecoration _buildInputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text("Enroll Student"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("PERSONAL INFORMATION"),
              _buildFormCard([
                TextFormField(
                  controller: _nameController,
                  decoration: _buildInputStyle("Student Full Name", Icons.person_outline_rounded),
                  validator: (v) => v!.isEmpty ? "Enter full name" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fatherNameController,
                  decoration: _buildInputStyle("Father's Name", Icons.badge_outlined),
                  validator: (v) => v!.isEmpty ? "Enter father's name" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputStyle("Contact Number", Icons.phone_android_rounded),
                  validator: (v) => v!.isEmpty ? "Enter contact number" : null,
                ),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader("ACADEMIC DETAILS"),
              _buildFormCard([
                TextFormField(
                  controller: _rollNumberController,
                  decoration: _buildInputStyle("Roll Number", Icons.tag_rounded),
                  validator: (v) => v!.isEmpty ? "Enter roll number" : null,
                ),
                const SizedBox(height: 16),
                _buildClassSelector(),
                const SizedBox(height: 16),
                if (_availableGroups.isNotEmpty) _buildGroupDropdown(),
                const SizedBox(height: 16),
                _buildDatePicker(),
              ]),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildSubmitButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF), letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildFormCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildClassSelector() {
    if (widget.classId != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const Icon(Icons.school_rounded, color: Color(0xFF4F46E5), size: 20),
            const SizedBox(width: 12),
            Text(_selectedClassName ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
          ],
        ),
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getClassesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        var classes = snapshot.data!.docs;
        return DropdownButtonFormField<String>(
          value: _selectedClassId,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: classes.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['name']))).toList(),
          onChanged: (value) {
            setState(() {
              _selectedClassId = value;
              var selectedDoc = classes.firstWhere((doc) => doc.id == value);
              _selectedClassName = selectedDoc['name'];
              _updateGroupOptions(_selectedClassName);
            });
          },
          decoration: _buildInputStyle("Select Class", Icons.school_outlined),
        );
      },
    );
  }

  Widget _buildGroupDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGroup,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      items: _availableGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
      onChanged: (v) => setState(() => _selectedGroup = v),
      decoration: _buildInputStyle("Student Group", Icons.group_outlined),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) setState(() => _selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: Color(0xFF4F46E5), size: 20),
            const SizedBox(width: 12),
            Text(
              _selectedDate == null ? 'Select Admission Date' : DateFormat('dd MMMM, yyyy').format(_selectedDate!),
              style: TextStyle(color: _selectedDate == null ? Colors.grey : const Color(0xFF1F2937), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
        boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: _saveStudent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text("ENROLL STUDENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
    );
  }
}