import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../models/expense.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'add_expense_screen.dart';
import 'receipt_screen.dart';
import 'sales_history_screen.dart';
import 'expense_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Cached once so any parent rebuild doesn't create new Stream
  // instances and reset both StreamBuilders back to
  // ConnectionState.waiting, which was flashing the whole dashboard
  // (and briefly showing the empty states) on every rebuild.
  late final Stream<List<Invoice>> _invoicesStream;
  late final Stream<List<Expense>> _expensesStream;

  @override
  void initState() {
    super.initState();
    _invoicesStream = _firestoreService.getTodayInvoices();
    _expensesStream = _firestoreService.getTodayExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Invoice>>(
      stream: _invoicesStream,
      builder: (context, invoiceSnapshot) {
        if (invoiceSnapshot.connectionState == ConnectionState.waiting) {
          return const _DashboardSkeleton();
        }

        if (invoiceSnapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load invoices: ${invoiceSnapshot.error}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        final invoices = invoiceSnapshot.data ?? [];

        int totalItemsSold = 0;
        double totalRevenue = 0;

        for (var invoice in invoices) {
          totalItemsSold += invoice.totalItemCount;
          totalRevenue += invoice.total;
        }

        return StreamBuilder<List<Expense>>(
          stream: _expensesStream,
          builder: (context, expenseSnapshot) {
            if (expenseSnapshot.connectionState == ConnectionState.waiting) {
              return const _DashboardSkeleton();
            }

            if (expenseSnapshot.hasError) {
              return Center(
                child: Text(
                  'Failed to load expenses: ${expenseSnapshot.error}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              );
            }

            final expenses = expenseSnapshot.data ?? [];

            double totalExpense = 0;
            for (var expense in expenses) {
              totalExpense += expense.amount;
            }

            final netAmount = totalRevenue - totalExpense;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Today's Summary",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Items Sold',
                          value: totalItemsSold.toString(),
                          color: const Color(0xFF2563EB),
                          bgColor: const Color(0xFFEFF6FF),
                          icon: Icons.shopping_bag_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Revenue',
                          value: '৳${totalRevenue.toStringAsFixed(2)}',
                          color: const Color(0xFF059669),
                          bgColor: const Color(0xFFECFDF5),
                          icon: Icons.trending_up_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Expenses',
                          value: '৳${totalExpense.toStringAsFixed(2)}',
                          color: const Color(0xFFDC2626),
                          bgColor: const Color(0xFFFEF2F2),
                          icon: Icons.trending_down_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Net Amount',
                          value: '৳${netAmount.toStringAsFixed(2)}',
                          color: netAmount >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                          bgColor: netAmount >= 0 ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _buildInvoicesColumn(context, invoices),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildExpensesColumn(context, expenses),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ------------------------------------------------------------
  // RECENT INVOICES COLUMN (compact, side-by-side)
  // ------------------------------------------------------------
  Widget _buildInvoicesColumn(BuildContext context, List<Invoice> invoices) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Invoices',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (invoices.length > 3)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesHistoryScreen()),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Text(
                    'All',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        invoices.isEmpty
            ? _EmptyStateCard(message: 'No sales yet today', icon: Icons.receipt_outlined, compact: true)
            : Column(
                children: invoices.take(3).map((invoice) {
                  final time = DateFormat('hh:mm a').format(invoice.date.toDate());
                  return _CompactListCard(
                    icon: Icons.description_outlined,
                    iconColor: AppColors.primary,
                    iconBgColor: AppColors.primary.withOpacity(0.08),
                    title: 'Invoice #${invoice.invoiceNumber}',
                    subtitle: time,
                    amount: '৳${invoice.total.toStringAsFixed(2)}',
                    amountColor: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReceiptScreen(invoice: invoice)),
                      );
                    },
                  );
                }).toList(),
              ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TODAY'S EXPENSES COLUMN (compact, side-by-side)
  // ------------------------------------------------------------
  Widget _buildExpensesColumn(BuildContext context, List<Expense> expenses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                "Today's Expenses",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.add_circle_outline, size: 18, color: AppColors.primary),
              ),
            ),
            if (expenses.length > 3)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ExpenseHistoryScreen()),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text(
                    'All',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        expenses.isEmpty
            ? _EmptyStateCard(message: 'No expenses added today', icon: Icons.money_off_outlined, compact: true)
            : Column(
                children: expenses.take(3).map((expense) {
                  return _CompactListCard(
                    icon: Icons.payments_outlined,
                    iconColor: const Color(0xFFDC2626),
                    iconBgColor: const Color(0xFFFEF2F2),
                    title: expense.title,
                    subtitle: expense.category,
                    amount: '৳${expense.amount.toStringAsFixed(2)}',
                    amountColor: const Color(0xFFDC2626),
                  );
                }).toList(),
              ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color bgColor;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool compact;

  const _EmptyStateCard({required this.message, required this.icon, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: compact ? 14 : 20, horizontal: compact ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: compact ? 24 : 32, color: Colors.grey.shade400),
          SizedBox(height: compact ? 4 : 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: compact ? 11 : 13),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// COMPACT LIST CARD (used in the side-by-side columns)
// ------------------------------------------------------------
class _CompactListCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final String amount;
  final Color amountColor;
  final VoidCallback? onTap;

  const _CompactListCard({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 14, color: iconColor),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: amountColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// SHIMMER PRIMITIVE
// ------------------------------------------------------------
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const _ShimmerBox({
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------
// DASHBOARD SKELETON (shown while streams are first loading)
// ------------------------------------------------------------
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  Widget _summaryCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ShimmerBox(width: 28, height: 28, borderRadius: BorderRadius.all(Radius.circular(8))),
          SizedBox(height: 12),
          _ShimmerBox(width: 60, height: 10),
          SizedBox(height: 10),
          _ShimmerBox(width: 80, height: 16),
        ],
      ),
    );
  }

  Widget _compactCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              _ShimmerBox(width: 26, height: 26, borderRadius: BorderRadius.all(Radius.circular(8))),
              SizedBox(width: 6),
              Expanded(child: _ShimmerBox(height: 10)),
            ],
          ),
          SizedBox(height: 8),
          _ShimmerBox(width: 60, height: 9),
          SizedBox(height: 6),
          _ShimmerBox(width: 50, height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ShimmerBox(width: 140, height: 18),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _summaryCardSkeleton()),
              const SizedBox(width: 12),
              Expanded(child: _summaryCardSkeleton()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _summaryCardSkeleton()),
              const SizedBox(width: 12),
              Expanded(child: _summaryCardSkeleton()),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ShimmerBox(width: 90, height: 13),
                    const SizedBox(height: 8),
                    _compactCardSkeleton(),
                    _compactCardSkeleton(),
                    _compactCardSkeleton(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _ShimmerBox(width: 90, height: 13),
                    const SizedBox(height: 8),
                    _compactCardSkeleton(),
                    _compactCardSkeleton(),
                    _compactCardSkeleton(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}