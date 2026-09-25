import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../widgets/verification_banner.dart';
import 'dashboard_screen.dart';
import 'add_expense_screen.dart';
import 'auth_gate.dart';

// Wraps DashboardScreen with its own AppBar (shop name, logout,
// verification banner) and a floating "Add Expense" button.
class DashboardTabWrapper extends StatelessWidget {
  DashboardTabWrapper({super.key});

  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/images/app_icon4.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        title: FutureBuilder<String>(
          future: _firestoreService.getShopName(),
          builder: (context, snapshot) {
            final shopName = snapshot.data ?? 'Dokandar';
            return Text(
              shopName,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 20),
              tooltip: 'Logout',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthGate()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const EmailVerificationBanner(),
          Expanded(child: DashboardScreen()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addExpenseFab',
        backgroundColor: const Color(0xFFDC2626),
        elevation: 3,
        tooltip: 'Add Expense',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
        child: const Icon(Icons.receipt_long_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}