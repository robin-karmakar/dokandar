import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

// Full standalone screen (used when navigating via "View All" from Dashboard)
class ExpenseHistoryScreen extends StatelessWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Expense History', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
      ),
      body: const ExpenseHistoryBody(),
    );
  }
}

class ExpenseHistoryBody extends StatefulWidget {
  const ExpenseHistoryBody({super.key});

  @override
  State<ExpenseHistoryBody> createState() => _ExpenseHistoryBodyState();
}

class _ExpenseHistoryBodyState extends State<ExpenseHistoryBody> with AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late final Stream<List<Expense>> _expensesStream;

  static const _expenseColor = Color(0xFFDC2626);
  static const _expenseBg = Color(0xFFFEF2F2);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _expensesStream = _firestoreService.getAllExpenses();
  }

  Map<String, List<Expense>> _groupExpensesByDate(List<Expense> expenses) {
    final Map<String, List<Expense>> grouped = {};

    for (var expense in expenses) {
      final dateKey = DateFormat('dd MMM yyyy').format(expense.date.toDate());
      grouped.putIfAbsent(dateKey, () => []).add(expense);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<List<Expense>>(
      stream: _expensesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Failed to load expenses: ${snapshot.error}', style: TextStyle(color: Colors.grey.shade600)),
          );
        }

        final expenses = snapshot.data ?? [];

        if (expenses.isEmpty) {
          return _buildEmptyState();
        }

        double totalExpense = 0;
        for (var expense in expenses) {
          totalExpense += expense.amount;
        }

        final groupedExpenses = _groupExpensesByDate(expenses);
        final dateKeys = groupedExpenses.keys.toList();

        return Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: _expenseBg, borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.trending_down_rounded, color: _expenseColor, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Expenses (All Time)',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('৳${totalExpense.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: _expenseColor)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                itemCount: dateKeys.length,
                itemBuilder: (context, index) {
                  final dateKey = dateKeys[index];
                  final expensesForDate = groupedExpenses[dateKey]!;

                  double dayTotal = 0;
                  for (var expense in expensesForDate) {
                    dayTotal += expense.amount;
                  }

                  return _buildDateSection(dateKey, expensesForDate, dayTotal);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateSection(String dateKey, List<Expense> expenses, double dayTotal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        elevation: 1.5,
        shadowColor: Colors.black.withOpacity(0.06),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            childrenPadding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
            title: Text(dateKey, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${expenses.length} expense${expenses.length == 1 ? '' : 's'}  •  ৳${dayTotal.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            children: expenses.map((expense) => _buildExpenseCard(expense)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final time = DateFormat('hh:mm a').format(expense.date.toDate());

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFB),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: _expenseBg, borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.payments_outlined, color: _expenseColor, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.title,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Flexible(
                        child: Text(expense.category,
                            overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: Colors.grey.shade400)),
                      const SizedBox(width: 8),
                      Text(time, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('৳${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, color: _expenseColor, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(color: _expenseBg, shape: BoxShape.circle),
              child: const Icon(Icons.receipt_long_rounded, size: 42, color: _expenseColor),
            ),
            const SizedBox(height: 20),
            const Text('No Expenses Yet', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Your recorded expenses will appear here.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}