import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/services/database_service.dart';
import 'package:universal_science_academy/features/admin_panel/presentation/screens/attendance_report_hub_screen.dart';
import 'classwise_fee_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  DateTime _selectedMonth = DateTime.now();

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + increment,
        1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.appBackground, // #F8F4EC
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // --- MODERN MINIMALIST MONTH SELECTOR ---
          _buildModernMonthPicker(),

          const SizedBox(height: 24),

          // --- PROFESSIONAL REVENUE CARD (NO GRADIENT) ---
          _buildProfessionalRevenueCard(),

          const SizedBox(height: 32),

          // --- SECTION HEADER ---
          const Text(
            "AVAILABLE REPORTS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9CA3AF),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // --- REPORT TILES ---
          _buildReportTile(
            icon: Icons.pie_chart_rounded,
            title: "Attendance Analytics",
            subtitle: "Class-wise presence & absence data",
            accentColor: const Color(0xFF8B5CF6),
            isAvailable: true,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AttendanceReportHubScreen(selectedMonth: _selectedMonth),
            )),
          ),
          const SizedBox(height: 12),
          _buildReportTile(
            icon: Icons.money_off_rounded,
            title: "Fee Defaulters List",
            subtitle: "Students with pending monthly fees",
            accentColor: const Color(0xFFEF4444),
            isAvailable: false,
          ),
          const SizedBox(height: 12),
          _buildReportTile(
            icon: Icons.trending_up_rounded,
            title: "Growth Analysis",
            subtitle: "Monthly admission & revenue trends",
            accentColor: const Color(0xFFF59E0B),
            isAvailable: false,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildModernMonthPicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navButton(Icons.chevron_left_rounded, () => _changeMonth(-1)),
          Column(
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(color: Color(0xFF1F2937), fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const Text("Selected Period", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          _navButton(
            Icons.chevron_right_rounded,
            _selectedMonth.month == DateTime.now().month && _selectedMonth.year == DateTime.now().year ? null : () => _changeMonth(1),
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback? onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: onTap == null ? Colors.grey.shade300 : const Color(0xFF4F46E5)),
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildProfessionalRevenueCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ClasswiseFeeReportScreen(selectedMonth: _selectedMonth),
        )),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF10B981), size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text("Total Fee Collection", style: TextStyle(color: Color(0xFF1F2937), fontSize: 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
                ],
              ),
              const SizedBox(height: 20),
              StreamBuilder<QuerySnapshot>(
                stream: _databaseService.getFeeCollectedForMonthStream(_selectedMonth),
                builder: (context, snapshot) {
                  double total = 0;
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data!.docs) {
                      total += (doc['amountPaid'] as num).toDouble();
                    }
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        NumberFormat.currency(locale: 'en_PK', symbol: 'Rs. ', decimalDigits: 0).format(total),
                        style: const TextStyle(color: Color(0xFF1F2937), fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
                          const SizedBox(width: 4),
                          Text(
                            "${snapshot.data?.docs.length ?? 0} Successful Payments",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportTile({required IconData icon, required String title, required String subtitle, required Color accentColor, bool isAvailable = true, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: isAvailable ? onTap : null,
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: accentColor, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1F2937))),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
        trailing: isAvailable 
          ? const Icon(Icons.chevron_right_rounded, color: Colors.grey)
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text("Soon", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            ),
      ),
    );
  }
}