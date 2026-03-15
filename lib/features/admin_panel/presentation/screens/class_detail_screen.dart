import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/models/class_model.dart';
import 'package:universal_science_academy/core/services/database_service.dart';
import 'package:universal_science_academy/core/services/list_export_service.dart';
import 'package:universal_science_academy/features/admin_panel/presentation/widgets/teacher_name_widget.dart';

// Screens
import 'add_student_screen.dart';
import 'add_subject_screen.dart';
import 'edit_student_screen.dart';
import 'edit_subject_screen.dart';
import 'student_detail_screen.dart';
import 'subject_report_options_screen.dart';

class ClassDetailScreen extends StatefulWidget {
  final ClassModel selectedClass;
  const ClassDetailScreen({super.key, required this.selectedClass});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _databaseService = DatabaseService();
  String _selectedStudentGroupFilter = 'All';
  List<String> _studentGroupFilters = ['All'];
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _setupStudentGroupFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setupStudentGroupFilters() {
    String lowerClassName = widget.selectedClass.name.toLowerCase();
    List<String> filters = ['All'];
    if (lowerClassName.contains('9') || lowerClassName.contains('10')) {
      filters.addAll(['Biology', 'Computer Science']);
    } else if (lowerClassName.contains('11') || lowerClassName.contains('12')) {
      filters.addAll(['FSC Pre-Medical', 'FSC Pre-Engineering', 'ICS']);
    }
    _studentGroupFilters = filters;
  }

  // Logic functions (PDF & Delete) remain identical to maintain functionality
  Future<void> _generateStudentListPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      QuerySnapshot studentSnapshot;
      if (_selectedStudentGroupFilter == 'All') {
        studentSnapshot = await _databaseService
            .getStudentsForClassStream(widget.selectedClass.id)
            .first;
      } else {
        studentSnapshot = await _databaseService
            .getStudentsForClassByGroupStream(
                widget.selectedClass.id, _selectedStudentGroupFilter)
            .first;
      }
      final students = studentSnapshot.docs;
      students.sort((a, b) {
        int rollA = int.tryParse((a.data() as Map)['rollNumber'] ?? '0') ?? 0;
        int rollB = int.tryParse((b.data() as Map)['rollNumber'] ?? '0') ?? 0;
        return rollA.compareTo(rollB);
      });
      await ListExportService.generateStudentListPdf(
        context: context,
        className: widget.selectedClass.name,
        groupName: _selectedStudentGroupFilter,
        students: students,
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to generate PDF: $e")));
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  void _showDeleteClassConfirmationDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Delete", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text("Are you sure you want to delete '${widget.selectedClass.name}'?\nThis will remove all students and subjects."),
        actions: [
          TextButton(child: const Text("Cancel", style: TextStyle(color: Colors.grey)), onPressed: () => Navigator.pop(ctx)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await _databaseService.deleteClassAndRelatedData(widget.selectedClass.id);
              if (mounted) {
                Navigator.pop(ctx);
                Navigator.pop(context);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: Text(widget.selectedClass.name, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1F2937))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_tabController.index == 1)
            _isGeneratingPdf
                ? const Center(child: Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
                : IconButton(icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF4F46E5)), onPressed: _generateStudentListPdf),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), onPressed: _showDeleteClassConfirmationDialog),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4F46E5),
          indicatorWeight: 3,
          labelColor: const Color(0xFF4F46E5),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          tabs: const [
            Tab(text: "SUBJECTS"),
            Tab(text: "STUDENTS"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildSubjectsTab(), _buildStudentsTab()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AddSubjectScreen(classId: widget.selectedClass.id)));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AddStudentScreen(classId: widget.selectedClass.id, className: widget.selectedClass.name)));
          }
        },
        backgroundColor: const Color(0xFF4F46E5),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(_tabController.index == 0 ? 'Add Subject' : 'Add Student', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSubjectsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _databaseService.getSubjectsForClassStream(widget.selectedClass.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState(icon: Icons.menu_book_rounded, message: "No subjects added yet.");
        
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          physics: const BouncingScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) => _buildSubjectCard(snapshot.data!.docs[index]),
        );
      },
    );
  }

  Widget _buildSubjectCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.book_rounded, color: Color(0xFF4F46E5), size: 22),
        ),
        title: Text(data['name'] ?? 'Subject', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
        subtitle: TeacherNameWidget(teacherId: data['teacherId']),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubjectReportOptionsScreen(classId: widget.selectedClass.id, className: widget.selectedClass.name, subjectId: doc.id, subjectName: data['name']))),
      ),
    );
  }

  Widget _buildStudentsTab() {
    return Column(
      children: [
        if (_studentGroupFilters.length > 1)
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _studentGroupFilters.length,
              itemBuilder: (context, index) {
                final filter = _studentGroupFilters[index];
                final isSelected = _selectedStudentGroupFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedStudentGroupFilter = filter),
                    backgroundColor: Colors.white,
                    selectedColor: const Color(0xFF4F46E5).withOpacity(0.1),
                    checkmarkColor: const Color(0xFF4F46E5),
                    labelStyle: TextStyle(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: isSelected ? const Color(0xFF4F46E5) : Colors.grey.withOpacity(0.2))),
                  ),
                );
              },
            ),
          ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _selectedStudentGroupFilter == 'All'
                ? _databaseService.getStudentsForClassStream(widget.selectedClass.id)
                : _databaseService.getStudentsForClassByGroupStream(widget.selectedClass.id, _selectedStudentGroupFilter),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState(icon: Icons.people_rounded, message: "No students in this group.");
              
              var students = snapshot.data!.docs;
              students.sort((a, b) => (int.tryParse(a['rollNumber'] ?? '0') ?? 0).compareTo(int.tryParse(b['rollNumber'] ?? '0') ?? 0));
              
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                physics: const BouncingScrollPhysics(),
                itemCount: students.length,
                itemBuilder: (context, index) => _buildStudentCard(students[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: const Color(0xFF4F46E5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Center(child: Text(data['rollNumber'] ?? '#', style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold))),
        ),
        title: Text(data['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
        subtitle: Text("Admitted: ${DateFormat.yMMMd().format((data['admissionDate'] as Timestamp).toDate())}", style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailScreen(studentDoc: doc))),
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.indigo.shade100),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        ],
      ),
    );
  }
}