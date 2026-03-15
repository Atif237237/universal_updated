import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/app/widgets/offline_banner.dart';
import 'package:universal_science_academy/features/admin_panel/presentation/widgets/admin_drawer.dart';
import 'package:universal_science_academy/features/auth/presentation/screens/login_role_screen.dart';
// Profile screen import
import 'package:universal_science_academy/features/admin_panel/presentation/screens/profile_screen.dart'; 
import 'reports_screen.dart';
import 'all_students_screen.dart';
import 'manage_screen.dart';
import 'teachers_list_screen.dart';
import 'admin_home_dashboard_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index && mounted) {
      HapticFeedback.lightImpact(); 
      setState(() => _selectedIndex = index);
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic, 
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      _onItemTapped(0);
      return false;
    }
    return await _showPremiumExitDialog();
  }

  // --- NEW: Premium Minimalist Exit Dialog ---
  Future<bool> _showPremiumExitDialog() async {
    return await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 40),
            const SizedBox(height: 16),
            const Text(
              "Exit Application?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Are you sure you want to close Universal Science Academy?",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Stay", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Exit Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ) ?? false;
  }

  Future<void> _signOut() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginRoleScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> widgetOptions = <Widget>[
      AdminHomeDashboardScreen(onCardTap: _onItemTapped),
      const AllStudentsScreen(),
      const TeachersListScreen(),
      const ClassesListScreen(), 
      const ReportsScreen(),
    ];

    const List<String> widgetTitles = [
      'Academy Overview',
      'Student Records',
      'Faculty Members',
      'Manage Classes',
      'Reports & Analytics',
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.appBackground, 
        drawer: AdminDrawer(
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
          onSignOut: _signOut,
        ),
        appBar: AppBar(
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark, 
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              widgetTitles[_selectedIndex],
              key: ValueKey<int>(_selectedIndex),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: -0.5,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent, 
          iconTheme: const IconThemeData(color: Color(0xFF4F46E5)), 
          flexibleSpace: Container(
            decoration: BoxDecoration(
              color: AppTheme.appBackground,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1,
                ),
              ),
            ),
          ),
          actions: [
            // --- UPDATED: Profile Icon Button ---
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_outline_rounded, color: Color(0xFF4F46E5), size: 22),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (index) {
                  if (mounted) setState(() => _selectedIndex = index);
                },
                children: widgetOptions,
              ),
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.grey.withOpacity(0.05), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BottomNavigationBar(
                elevation: 0,
                backgroundColor: Colors.white,
                selectedItemColor: const Color(0xFF4F46E5), 
                unselectedItemColor: Colors.grey.withOpacity(0.5),
                showUnselectedLabels: false,
                showSelectedLabels: true,
                type: BottomNavigationBarType.fixed,
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w800, 
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
                items: [
                  _buildNavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Home'),
                  _buildNavItem(Icons.people_outline_rounded, Icons.people_rounded, 'Students'),
                  _buildNavItem(Icons.school_outlined, Icons.school_rounded, 'Teachers'),
                  _buildNavItem(Icons.layers_outlined, Icons.layers_rounded, 'Classes'),
                  _buildNavItem(Icons.analytics_outlined, Icons.analytics_rounded, 'Reports'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData unselected, IconData selected, String label) {
    return BottomNavigationBarItem(
      icon: Icon(unselected, size: 24),
      activeIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF4F46E5).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(selected, size: 24),
      ),
      label: label,
    );
  }
}