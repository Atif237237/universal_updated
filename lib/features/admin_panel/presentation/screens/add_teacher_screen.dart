import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:universal_science_academy/core/models/teacher_model.dart';
import '../../../../app/widgets/custom_text_field.dart';
import '../../../../app/widgets/primary_button.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _teacherIdController =
      TextEditingController(); // Added controller for Teacher ID
  bool _isLoading = false;

  Future<void> _addTeacher() async {
    // Added check for teacherIdController
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _teacherIdController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields.")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Step 1: Create user in Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      User? newUser = userCredential.user;

      if (newUser != null) {
        String teacherName = _nameController.text.trim();
        // Step 2: Save teacher details in Cloud Firestore
        Teacher teacher = Teacher(
          uid: newUser.uid,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          teacherId: _teacherIdController.text.trim(),
          //Added Teacher ID
        );

        await FirebaseFirestore.instance
            .collection('teachers')
            .doc(newUser.uid)
            .set({
              'uid': newUser.uid,
              'name': teacherName,
              'email': _emailController.text.trim(),
              'teacherId': _teacherIdController.text.trim(),
              'searchName': teacherName.toLowerCase(), // <-- ADD THIS LINE
            });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Teacher Added Successfully!")),
        );
        Navigator.of(context).pop(); // Go back to the previous screen
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _teacherIdController.dispose(); // Dispose the new controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Teacher")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(controller: _nameController, hintText: "Full Name"),
            const SizedBox(height: 20),
            // Added TextField for Teacher ID
            CustomTextField(
              controller: _teacherIdController,
              hintText: "Teacher ID (e.g., TID123)",
            ),
            const SizedBox(height: 20),
            CustomTextField(controller: _emailController, hintText: "Email"),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _passwordController,
              hintText: "Password",
              isPassword: true, // It's good practice to obscure password fields
            ),
            const SizedBox(height: 40),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : PrimaryButton(text: "Save Teacher", onPressed: _addTeacher),
          ],
        ),
      ),
    );
  }
}
