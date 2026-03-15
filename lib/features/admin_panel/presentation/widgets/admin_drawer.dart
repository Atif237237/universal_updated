import 'package:flutter/material.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/features/admin_panel/presentation/screens/academic_report_hub_screen.dart';
import 'package:universal_science_academy/features/admin_panel/presentation/screens/profile_screen.dart';
import 'package:universal_science_academy/features/admin_panel/presentation/screens/quick_fee_entry_screen.dart';

class AdminDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final VoidCallback onSignOut;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.appBackground, // #F8F4EC
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          // --- MODERN BRANDING HEADER ---
          _buildDrawerHeader(),

          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                const SizedBox(height: 10),
                _buildSectionLabel("MAIN NAVIGATION"),
                _buildDrawerItem(0, Icons.dashboard_rounded, 'Dashboard'),
                _buildDrawerItem(1, Icons.people_rounded, 'Students'),
                _buildDrawerItem(2, Icons.school_rounded, 'Teachers'),
                _buildDrawerItem(3, Icons.layers_rounded, 'Classes'),
                _buildDrawerItem(4, Icons.analytics_rounded, 'Fee Reports'),
                
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
                ),

                _buildSectionLabel("QUICK ACTIONS"),
                _buildActionTile(
                  icon: Icons.bolt_rounded,
                  text: "Quick Fee Entry",
                  color: const Color(0xFF10B981), // Emerald
                  onTap: () => _navigateTo(context, const QuickFeeEntryScreen()),
                ),
                _buildActionTile(
                  icon: Icons.assessment_rounded,
                  text: "Academic Reports",
                  color: const Color(0xFFF59E0B), // Amber
                  onTap: () => _navigateTo(context, const AcademicReportHubScreen()),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
                ),

                _buildSectionLabel("ACCOUNT"),
                _buildActionTile(
                  icon: Icons.person_outline_rounded,
                  text: "My Profile",
                  color: const Color(0xFF4F46E5),
                  onTap: () => _navigateTo(context, const ProfileScreen()),
                ),
              ],
            ),
          ),

          // --- LOGOUT SECTION ---
          _buildLogoutSection(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF4F46E5), size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Universal Academy",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
                ),
                Text(
                  "Admin Portal",
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF9CA3AF), letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String text) {
    final bool isSelected = selectedIndex == index;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4F46E5).withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        onTap: () => onItemTapped(index),
        dense: true,
        leading: Icon(icon, color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF6B7280), size: 22),
        title: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF374151),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        trailing: isSelected 
            ? Container(width: 4, height: 16, decoration: BoxDecoration(color: const Color(0xFF4F46E5), borderRadius: BorderRadius.circular(10)))
            : null,
      ),
    );
  }

  Widget _buildActionTile({required IconData icon, required String text, required Color color, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      dense: true,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
      trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: InkWell(
        onTap: onSignOut,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 16),
              const Text("Sign Out", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}