import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/services/database_service.dart';
import 'package:universal_science_academy/features/admin_panel/presentation/screens/quick_fee_entry_screen.dart';
import 'add_teacher_screen.dart';
import 'add_class_screen.dart';

class AdminHomeDashboardScreen extends StatefulWidget {
  final Function(int) onCardTap;
  const AdminHomeDashboardScreen({super.key, required this.onCardTap});

  @override
  State<AdminHomeDashboardScreen> createState() => _AdminHomeDashboardScreenState();
}

class _AdminHomeDashboardScreenState extends State<AdminHomeDashboardScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _cardAnimations;
  late Animation<double> _headerAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _cardAnimations = List.generate(4, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(0.1 + (index * 0.1), 0.7 + (index * 0.1), curve: Curves.easeOutQuart),
        ),
      );
    });

    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();
    final formatCurrency = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.appBackground,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildWelcomeHeader(context)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.15, // Slightly wider for better text fit
                ),
                delegate: SliverChildListDelegate([
                  _buildModernStatCard(
                    animation: _cardAnimations[0],
                    title: "Students",
                    dataFuture: db.getTotalCount('students').then((val) => val.toString()),
                    icon: Icons.people_alt_rounded,
                    accentColor: const Color(0xFF6366F1), // Indigo
                    onTap: () => widget.onCardTap(1),
                  ),
                  _buildModernStatCard(
                    animation: _cardAnimations[1],
                    title: "Teachers",
                    dataFuture: db.getTotalCount('teachers').then((val) => val.toString()),
                    icon: Icons.school_rounded,
                    accentColor: const Color(0xFFEC4899), // Pink
                    onTap: () => widget.onCardTap(2),
                  ),
                  _buildModernStatCard(
                    animation: _cardAnimations[2],
                    title: "Classes",
                    dataFuture: db.getTotalCount('classes').then((val) => val.toString()),
                    icon: Icons.class_rounded,
                    accentColor: const Color(0xFF06B6D4), // Cyan
                    onTap: () => widget.onCardTap(3),
                  ),
                  _buildModernStatCard(
                    animation: _cardAnimations[3],
                    title: "Today's Revenue",
                    dataFuture: db.getFeesCollectedToday().then((val) => formatCurrency.format(val)),
                    icon: Icons.payments_rounded,
                    accentColor: const Color(0xFF10B981), // Emerald
                    onTap: () => widget.onCardTap(4),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
            SliverToBoxAdapter(child: _buildQuickActions(context)),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatCard({
    required Animation<double> animation,
    required String title,
    required Future<String> dataFuture,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: animation.drive(Tween(begin: const Offset(0, 0.1), end: Offset.zero)),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Side Accent Indicator
                  Positioned(
                    left: 0,
                    top: 20,
                    bottom: 20,
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
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
                          child: Icon(icon, color: accentColor, size: 20),
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<String>(
                              future: dataFuture,
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data ?? '...',
                                  style: const TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                            Text(
                              title,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return FadeTransition(
      opacity: _headerAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Overview",
                    style: TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Academy Insights",
                    style: TextStyle(
                      color: Colors.blueGrey.shade900,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd').format(DateTime.now()),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MANAGEMENT ACTIONS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9CA3AF),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Quick Fee Tile - Full Width & Elegant
          _buildActionTile(
            context,
            title: "Quick Fee Entry",
            subtitle: "Process student payments in seconds",
            icon: Icons.bolt_rounded,
            accentColor: const Color(0xFFF59E0B),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickFeeEntryScreen())),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSmallActionCard(
                  context,
                  title: "Add Teacher",
                  icon: Icons.person_add_rounded,
                  accentColor: const Color(0xFF4F46E5),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddTeacherScreen())),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSmallActionCard(
                  context,
                  title: "Add Class",
                  icon: Icons.add_business_rounded,
                  accentColor: const Color(0xFF7C3AED),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddClassScreen())),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color accentColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: accentColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1F2937))),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionCard(BuildContext context, {required String title, required IconData icon, required Color accentColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: accentColor, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F2937)),
            ),
          ],
        ),
      ),
    );
  }
}