import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/services/database_service.dart';
import 'package:universal_science_academy/features/admin_panel/presentation/screens/teacher_student_detail_screen.dart';
import 'edit_student_screen.dart';

class AllStudentsScreen extends StatefulWidget {
  const AllStudentsScreen({super.key});

  @override
  State<AllStudentsScreen> createState() => _AllStudentsScreenState();
}

class _AllStudentsScreenState extends State<AllStudentsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String? _selectedClassId;
  Map<String, String> _classNames = {};
  bool _areClassesLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) setState(() => _searchQuery = _searchController.text);
    });
    _loadClassNames();
  }

  Future<void> _loadClassNames() async {
    try {
      final classSnapshot = await _databaseService.getClassesStream().first;
      if (mounted) {
        setState(() {
          _classNames = {for (var doc in classSnapshot.docs) doc.id: doc['name']};
          _areClassesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _areClassesLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground, // #F8F4EC
      body: Column(
        children: [
          _buildTopFilterHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _databaseService.getAllStudentsStream(
                query: _searchQuery,
                classId: _selectedClassId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                var students = snapshot.data!.docs;
                students.sort((a, b) {
                  int rollA = int.tryParse((a.data() as Map)['rollNumber'] ?? '0') ?? 0;
                  int rollB = int.tryParse((b.data() as Map)['rollNumber'] ?? '0') ?? 0;
                  return rollA.compareTo(rollB);
                });

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  physics: const BouncingScrollPhysics(),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    return _buildStudentCard(students[index], index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFilterHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      color: AppTheme.appBackground,
      child: Column(
        children: [
          // Search Field with 1px Border & Radius
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1), // 1px Border
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: TextField(
              controller: _searchController,
              cursorColor: const Color(0xFF4F46E5),
              decoration: InputDecoration(
                hintText: "Search students by name...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF4F46E5), size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Dropdown with 1px Border & Radius
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1), // 1px Border
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _selectedClassId,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                icon: const Icon(Icons.expand_more_rounded, color: Colors.grey),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.filter_list_rounded, size: 18, color: Colors.grey),
                  contentPadding: EdgeInsets.zero,
                ),
                hint: const Text("Filter by Class", style: TextStyle(fontSize: 13, color: Colors.grey)),
                onChanged: (value) => setState(() => _selectedClassId = value),
                items: [
                  const DropdownMenuItem(value: null, child: Text("All Classes")),
                  ..._classNames.entries.map((entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value, style: const TextStyle(fontSize: 14)),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(DocumentSnapshot studentDoc, int index) {
  var studentData = studentDoc.data() as Map<String, dynamic>;
  String name = studentData['name'] ?? 'No Name';
  String className = _classNames[studentData['classId']] ?? 'N/A';
  String rollNo = studentData['rollNumber']?.toString() ?? '0';

  return TweenAnimationBuilder(
    duration: Duration(milliseconds: 400 + (index * 50)),
    tween: Tween<double>(begin: 0, end: 1),
    builder: (context, double value, child) {
      return Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      );
    },
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        // PROFESSIONAL 1PX BORDER
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), 
            blurRadius: 10, 
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        // LEADING: ROLL NUMBER (Subtle Accent Style)
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2), width: 1),
          ),
          child: Center(
            child: Text(
              rollNo,
              style: const TextStyle(
                color: Color(0xFF4F46E5), 
                fontWeight: FontWeight.w900, 
                fontSize: 16,
              ),
            ),
          ),
        ),
        // TITLE: STUDENT NAME
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w800, 
            color: Color(0xFF1F2937), 
            fontSize: 16,
          ),
        ),
        // SUBTITLE: CLASS NAME (Minimalist Text)
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            className,
            style: TextStyle(
              color: Colors.grey.shade500, 
              fontSize: 12, 
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        // TRAILING: POPUP ACTIONS
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => EditStudentScreen(studentDoc: studentDoc)),
              );
            } else if (value == 'delete') {
              _showDeleteConfirmationDialog(studentDoc.id, name);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit', 
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey.shade700),
                  const SizedBox(width: 10),
                  const Text('Edit Details'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete', 
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                  SizedBox(width: 10),
                  Text('Remove Student', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        // ON TAP: DETAIL VIEW
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TeacherStudentDetailScreen(studentDoc: studentDoc),
            ),
          );
        },
      ),
    ),
  );
}
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
            child: Icon(Icons.person_search_rounded, size: 60, color: Colors.indigo.shade200),
          ),
          const SizedBox(height: 20),
          const Text("No Students Found", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Text("Try adjusting your filters or search query.", style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Delete", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete '$studentName'?\nThis action is permanent."),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              await _databaseService.deleteStudent(studentId);
              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("'$studentName' deleted"), backgroundColor: Colors.redAccent));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}