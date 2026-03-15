import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/models/class_model.dart';
import 'package:universal_science_academy/core/services/database_service.dart';
import 'package:universal_science_academy/features/admin_panel/presentation/screens/add_student_screen.dart';
import 'add_class_screen.dart';
import 'class_detail_screen.dart';

class ClassesListScreen extends StatelessWidget {
  const ClassesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService databaseService = DatabaseService();

    // Modern Professional Palette for Class Cards
    final List<Color> accentColors = [
      const Color(0xFF4F46E5), // Indigo
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF8B5CF6), // Violet
    ];

    return Scaffold(
      backgroundColor: AppTheme.appBackground, // #F8F4EC
      // Yahan koi AppBar ya Custom Header nahi hai kyunke Dashboard ka AppBar upar maujood hai
      body: StreamBuilder<QuerySnapshot>(
        stream: databaseService.getClassesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5))
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          var classDocs = snapshot.data!.docs;

          return GridView.builder(
            // Padding ko adjust kiya hai taake Top AppBar se thoda gap rahe
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.05,
            ),
            itemCount: classDocs.length,
            itemBuilder: (context, index) {
              var classData = classDocs[index].data() as Map<String, dynamic>;
              final classModel = ClassModel.fromMap(classData, classDocs[index].id);
              final accentColor = accentColors[index % accentColors.length];

              return GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ClassDetailScreen(selectedClass: classModel),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.withOpacity(0.12), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Subtle background icon layer
                      Positioned(
                        right: -10,
                        bottom: -10,
                        child: Icon(
                          Icons.school_rounded,
                          size: 65, 
                          color: accentColor.withOpacity(0.04)
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.class_rounded,
                                  color: accentColor, size: 22),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  classModel.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: Color(0xFF1F2937)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "View Records",
                                  style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      
      // --- SPEED DIAL ---
      floatingActionButton: SpeedDial(
        icon: Icons.add_rounded,
        activeIcon: Icons.close_rounded,
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 8,
        spacing: 12,
        spaceBetweenChildren: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        overlayColor: Colors.black,
        overlayOpacity: 0.15,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.person_add_rounded, size: 20),
            label: 'Add New Student',
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF4F46E5),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddStudentScreen()),
            ),
          ),
          SpeedDialChild(
            child: const Icon(Icons.domain_add_rounded, size: 20),
            label: 'Create New Class',
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF10B981),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AddClassScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.category_outlined, size: 64, color: const Color(0xFF4F46E5).withOpacity(0.3)),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Classes Found",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 4),
          Text(
            "Tap '+' to set up your first class",
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}