import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/services/database_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherStudentDetailScreen extends StatefulWidget {
  final DocumentSnapshot studentDoc;
  const TeacherStudentDetailScreen({super.key, required this.studentDoc});

  @override
  State<TeacherStudentDetailScreen> createState() => _TeacherStudentDetailScreenState();
}

class _TeacherStudentDetailScreenState extends State<TeacherStudentDetailScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String? _className;

  @override
  void initState() {
    super.initState();
    _fetchClassName();
  }

  Future<void> _fetchClassName() async {
    try {
      final classId = widget.studentDoc['classId'];
      final doc = await _databaseService.getClassById(classId);
      if (mounted && doc.exists) {
        setState(() => _className = doc['name']);
      }
    } catch (e) {
      if (mounted) setState(() => _className = 'N/A');
    }
  }

  // --- WHATSAPP LAUNCH LOGIC ---
  Future<void> _launchWhatsApp(String phoneNumber) async {
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    
    String finalNumber = cleanNumber;
    if (cleanNumber.startsWith('0')) {
      finalNumber = '92${cleanNumber.substring(1)}';
    } else if (!cleanNumber.startsWith('92')) {
      finalNumber = '92$cleanNumber';
    }

    final Uri whatsappUrl = Uri.parse("https://wa.me/$finalNumber");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'WhatsApp not installed';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not open WhatsApp: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentData = widget.studentDoc.data() as Map<String, dynamic>;
    final admissionDate = (studentData['admissionDate'] as Timestamp).toDate();
    final phoneNumber = studentData['phoneNumber'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      appBar: AppBar(
        title: const Text("Student Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildProfileHeader(studentData),
            
            const SizedBox(height: 24),
            
            // --- UPDATED: Using WhatsApp Action instead of Call ---
            if (phoneNumber.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildWhatsAppAction(phoneNumber),
              ),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ACADEMIC & PERSONAL DETAILS",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF9CA3AF),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailCard(
                    items: [
                      _detailItem(Icons.person_outline_rounded, "Father's Name", studentData['fatherName'] ?? 'N/A'),
                      _detailItem(Icons.school_outlined, "Current Class", _className ?? "Loading..."),
                      _detailItem(Icons.group_work_outlined, "Student Group", studentData['studentGroup'] ?? 'N/A'),
                      _detailItem(Icons.calendar_today_rounded, "Admission Date", DateFormat('dd MMMM, yyyy').format(admissionDate)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- PROFILE HEADER ---
  Widget _buildProfileHeader(Map<String, dynamic> data) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.1), width: 4),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Center(
            child: Text(
              data['name']?.substring(0, 1).toUpperCase() ?? 'S',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          data['name'] ?? 'N/A',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "ROLL NO: ${data['rollNumber'] ?? 'N/A'}",
            style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ],
    );
  }

  // --- WHATSAPP ACTION BUTTON ---
  Widget _buildWhatsAppAction(String phone) {
    return InkWell(
      onTap: () => _launchWhatsApp(phone),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF25D366).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF25D366).withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            const CircleAvatar(
            backgroundColor: Color(0xFF25D366), // Official WhatsApp Green
            child: Icon(
              Icons.chat_bubble_rounded, // 👈 'whatsapp_rounded' ki jagah ye use karein
              color: Colors.white, 
              size: 20,
            ),
          ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Message on WhatsApp", 
                      style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                  Text(phone, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.send_rounded, size: 16, color: Color(0xFF25D366)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({required List<Widget> items}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(children: items),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: const Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}