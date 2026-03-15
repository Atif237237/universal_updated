import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:universal_science_academy/core/services/database_service.dart';
import 'package:universal_science_academy/app/widgets/primary_button.dart';

class AddSubjectScreen extends StatefulWidget {
  final String classId;
  // Parameters to pre-fill the form
  final String? initialSubjectName;
  final String? initialSubjectType;

  const AddSubjectScreen({
    super.key,
    required this.classId,
    this.initialSubjectName,
    this.initialSubjectType,
  });

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  String? _selectedTeacherId;
  String _subjectType = 'Compulsory'; // Default value
  bool _isLoading = false;
  bool _isSubjectNameEditable = true; // Controls if the text field is editable

  @override
  void initState() {
    super.initState();
    // If an initial name is passed, set the controller and make the field read-only
    if (widget.initialSubjectName != null) {
      _subjectNameController.text = widget.initialSubjectName!;
      _isSubjectNameEditable = false;
    }
    // If an initial type is passed, set the subject type
    if (widget.initialSubjectType != null) {
      _subjectType = widget.initialSubjectType!;
    }
  }

  void _saveSubject() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _databaseService.addSubject(
          _subjectNameController.text.trim(),
          widget.classId,
          _selectedTeacherId!,
          _subjectType,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Subject Added/Assigned Successfully!")),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Failed to add subject: $e")));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSubjectNameEditable ? "Add New Subject" : "Assign Teacher",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _subjectNameController,
                // Make field read-only if name is pre-filled from the previous screen
                readOnly: !_isSubjectNameEditable,
                decoration: InputDecoration(
                  labelText: "Subject Name",
                  hintText: "e.g., Physics",
                  filled: !_isSubjectNameEditable,
                  fillColor: Colors.grey[200],
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a subject name' : null,
              ),
              const SizedBox(height: 20),

              // Only show the type dropdown if we are adding a new compulsory subject
              if (_isSubjectNameEditable)
                DropdownButtonFormField<String>(
                  initialValue: _subjectType,
                  items: ['Compulsory', 'Optional'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) =>
                      setState(() => _subjectType = newValue!),
                  decoration: const InputDecoration(labelText: "Subject Type"),
                ),
              const SizedBox(height: 20),

              StreamBuilder<QuerySnapshot>(
                stream: _databaseService.getTeachersStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  var teachers = snapshot.data!.docs.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['name']),
                    );
                  }).toList();

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedTeacherId,
                    hint: const Text("Select Teacher"),
                    items: teachers,
                    onChanged: (value) =>
                        setState(() => _selectedTeacherId = value),
                    validator: (value) =>
                        value == null ? 'Please select a teacher' : null,
                    decoration: const InputDecoration(
                      labelText: "Assign to Teacher",
                    ),
                  );
                },
              ),
              const Spacer(),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      text: "Save Subject",
                      onPressed: _saveSubject,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
