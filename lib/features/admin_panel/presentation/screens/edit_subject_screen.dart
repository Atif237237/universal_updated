import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:universal_science_academy/core/services/database_service.dart';
import 'package:universal_science_academy/app/widgets/primary_button.dart';

class EditSubjectScreen extends StatefulWidget {
  final DocumentSnapshot subjectDoc;
  const EditSubjectScreen({super.key, required this.subjectDoc});

  @override
  State<EditSubjectScreen> createState() => _EditSubjectScreenState();
}

class _EditSubjectScreenState extends State<EditSubjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subjectNameController;
  final DatabaseService _databaseService = DatabaseService();
  String? _selectedTeacherId;
  bool _isLoading = false;

  // --- NEW: State variable for subject type ---
  String _subjectType = 'Compulsory';

  @override
  void initState() {
    super.initState();
    final data = widget.subjectDoc.data() as Map<String, dynamic>;

    _subjectNameController = TextEditingController(text: data['name']);
    _selectedTeacherId = data['teacherId'];

    // --- NEW: Load the existing subject type, default to 'Compulsory' if not present ---
    _subjectType = data['subjectType'] ?? 'Compulsory';
  }

  // --- UPDATED: This function now saves the subject type as well ---
  void _updateSubject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      await _databaseService.updateSubject(
        widget.subjectDoc.id,
        _subjectNameController.text.trim(),
        _selectedTeacherId!,
        _subjectType, // Pass the selected subject type
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Subject Updated Successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update subject: $e")));
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
  void dispose() {
    _subjectNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Subject")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _subjectNameController,
                decoration: const InputDecoration(labelText: "Subject Name"),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a subject name'
                    : null,
              ),
              const SizedBox(height: 20),

              // --- NEW: Dropdown to select Subject Type ---
              DropdownButtonFormField<String>(
                initialValue: _subjectType,
                items: ['Compulsory', 'Optional'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _subjectType = newValue!;
                  });
                },
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
                    onChanged: (value) {
                      setState(() {
                        _selectedTeacherId = value;
                      });
                    },
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
                      text: "Save Changes",
                      onPressed: _updateSubject,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
