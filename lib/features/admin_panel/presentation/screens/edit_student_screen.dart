import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/services/database_service.dart';

class EditStudentScreen extends StatefulWidget {
  final DocumentSnapshot studentDoc;
  const EditStudentScreen({super.key, required this.studentDoc});

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _fatherNameController;
  late TextEditingController _rollNumberController;
  late TextEditingController _phoneController;

  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;
  String? _selectedGroup;
  List<String> _availableGroups = [];
  bool _isClassDataLoading = true;

  @override
  void initState() {
    super.initState();
    final data = widget.studentDoc.data() as Map<String, dynamic>;

    _nameController = TextEditingController(text: data['name'] ?? '');
    _fatherNameController = TextEditingController(text: data['fatherName'] ?? '');
    _rollNumberController = TextEditingController(text: data['rollNumber'] ?? '');
    _phoneController = TextEditingController(text: data['phoneNumber'] ?? '');
    _selectedGroup = data['studentGroup'];
    _loadClassData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _rollNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadClassData() async {
    try {
      final data = widget.studentDoc.data() as Map<String, dynamic>;
      final classId = data['classId'];
      final classDoc = await _databaseService.getClassById(classId);

      if (mounted && classDoc.exists) {
        final className = classDoc['name'];
        _updateGroupOptions(className);
      }
    } catch (e) {
      debugPrint("Error loading class data: $e");
    } finally {
      if (mounted) setState(() => _isClassDataLoading = false);
    }
  }

  void _updateGroupOptions(String? className) {
    if (className == null) return;
    String lowerClassName = className.toLowerCase();
    List<String> groups = [];
    if (lowerClassName.contains('9') || lowerClassName.contains('10')) {
      groups = ['Biology', 'Computer Science'];
    } else if (lowerClassName.contains('11') || lowerClassName.contains('12')) {
      groups = ['FSC Pre-Medical', 'FSC Pre-Engineering', 'ICS'];
    } else {
      groups = ['General'];
    }
    setState(() {
      _availableGroups = groups;
      if (!_availableGroups.contains(_selectedGroup)) {
        _selectedGroup = _availableGroups.isNotEmpty ? _availableGroups.first : null;
      }
    });
  }

  void _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _databaseService.updateStudent(
        widget.studentDoc.id,
        _nameController.text.trim(),
        _fatherNameController.text.trim(),
        _rollNumberController.text.trim(),
        _selectedGroup!,
        _phoneController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar("Student profile updated successfully!", isError: false);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Failed to update: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text("Edit Student"),
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
                  decoration: _buildInputStyle("Full Name", Icons.person_outline_rounded),
                  validator: (v) => v!.isEmpty ? "Enter name" : null,
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
                  validator: (v) => v!.isEmpty ? "Enter phone number" : null,
                ),
              ]),
              const SizedBox(height: 32),
              _buildSectionHeader("ACADEMIC RECORD"),
              _buildFormCard([
                TextFormField(
                  controller: _rollNumberController,
                  decoration: _buildInputStyle("Roll Number", Icons.tag_rounded),
                  validator: (v) => v!.isEmpty ? "Enter roll no" : null,
                ),
                const SizedBox(height: 16),
                if (_isClassDataLoading)
                  const LinearProgressIndicator()
                else
                  DropdownButtonFormField<String>(
                    value: _selectedGroup,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    items: _availableGroups.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (v) => setState(() => _selectedGroup = v),
                    decoration: _buildInputStyle("Academic Group", Icons.layers_outlined),
                  ),
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
        onPressed: _updateStudent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ),
    );
  }
}