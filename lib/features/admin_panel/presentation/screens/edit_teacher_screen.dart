import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:universal_science_academy/core/services/database_service.dart';
// Apne custom widgets ke path zaroor check kar lein
import 'package:universal_science_academy/app/widgets/custom_text_field.dart';
import 'package:universal_science_academy/app/widgets/primary_button.dart';

class EditTeacherScreen extends StatefulWidget {
  final DocumentSnapshot teacherDoc;
  const EditTeacherScreen({super.key, required this.teacherDoc});

  @override
  State<EditTeacherScreen> createState() => _EditTeacherScreenState();
}

class _EditTeacherScreenState extends State<EditTeacherScreen> {
  // Form aur Controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _teacherIdController;

  // Services aur State
  final DatabaseService _databaseService = DatabaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Teacher ka data text fields mein pehle se daal dein
    _nameController = TextEditingController(text: widget.teacherDoc['name']);
    _emailController = TextEditingController(text: widget.teacherDoc['email']);
    _teacherIdController = TextEditingController(
      text: widget.teacherDoc['teacherId'],
    );
  }

  @override
  void dispose() {
    // Controllers ko hamesha dispose karein
    _nameController.dispose();
    _emailController.dispose();
    _teacherIdController.dispose();
    super.dispose();
  }

  // --- Teacher ki details update karne ka function ---
  void _updateTeacher() async {
    // Form validation check
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.updateTeacher(
        widget.teacherDoc.id,
        _nameController.text.trim(),
        _emailController.text.trim(),
        _teacherIdController.text.trim(),
      );

      // Screen band karne se pehle 'mounted' check karein
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Teacher Updated Successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update teacher: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. AppBar se hardcoded colors hata diye gaye hain.
      // Ab yeh app ki theme ke 'primary' aur 'onPrimary' colors istemal karega.
      appBar: AppBar(title: const Text("Edit Teacher")),

      // 2. Body se extra Container bhi hata diya gaya hai.
      // Scaffold ab khud theme ke hisab se background ('scaffoldBackgroundColor') set karega.
      body: SingleChildScrollView(
        // Keyboard aane par screen overflow na ho
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _nameController,
                hintText: "Full Name",
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 20),
              // Email field ko read-only rakha hai kyunke yeh Firebase Auth se link ho sakta hai
              CustomTextField(
                controller: _emailController,
                hintText: "Email",
                isReadOnly: true,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _teacherIdController,
                hintText: "Teacher ID",
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a Teacher ID' : null,
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      text: "Save Changes",
                      onPressed: _updateTeacher,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
