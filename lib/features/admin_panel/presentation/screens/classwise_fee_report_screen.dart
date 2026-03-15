import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_science_academy/app/theme/app_theme.dart';
import 'package:universal_science_academy/core/services/database_service.dart';
import 'student_fee_status_screen.dart';

class ClasswiseFeeReportScreen extends StatelessWidget {
  final DateTime selectedMonth;

  const ClasswiseFeeReportScreen({super.key, required this.selectedMonth});

  @override
  Widget build(BuildContext context) {
    final DatabaseService db = DatabaseService();
    final formatCurrency = NumberFormat.currency(
      locale: 'en_PK',
      symbol: 'Rs. ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppTheme.appBackground, // #F8F4EC
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            const Text(
              "Class-wise Fee Reports",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              DateFormat('MMMM yyyy').format(selectedMonth),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.getClassesStream(),
        builder: (context, classSnapshot) {
          if (!classSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (classSnapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: classSnapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var classDoc = classSnapshot.data!.docs[index];
              return _buildClassReportCard(context, classDoc, db, formatCurrency);
            },
          );
        },
      ),
    );
  }

  Widget _buildClassReportCard(BuildContext context, DocumentSnapshot classDoc,
      DatabaseService db, NumberFormat formatCurrency) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.getFeeCollectedForMonthStreamForClass(
        classDoc.id,
        selectedMonth,
      ),
      builder: (context, feeSnapshot) {
        double total = 0;
        int totalPayments = 0;

        if (feeSnapshot.hasData) {
          totalPayments = feeSnapshot.data!.docs.length;
          for (var doc in feeSnapshot.data!.docs) {
            total += (doc['amountPaid'] as num).toDouble();
          }
        }

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StudentFeeStatusScreen(
                  classId: classDoc.id,
                  className: classDoc['name'],
                  selectedMonth: selectedMonth,
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.withOpacity(0.15), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Background subtle icon
                Positioned(
                  right: -5,
                  bottom: -5,
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 50,
                    color: const Color(0xFF4F46E5).withOpacity(0.03),
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
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Color(0xFF4F46E5),
                          size: 20,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classDoc['name'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          if (feeSnapshot.connectionState == ConnectionState.waiting)
                            const SizedBox(
                              height: 15,
                              width: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatCurrency.format(total),
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF4F46E5),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "$totalPayments Slips",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
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
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 64, color: Colors.indigo.shade100),
          const SizedBox(height: 16),
          const Text(
            "No Records Found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}