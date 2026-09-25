import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';
import '../services/firestore_service.dart';
import 'receipt_screen.dart';

// Full standalone screen (used when navigating via "View All" from Dashboard)
class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text('Sales History', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
      ),
      body: const SalesHistoryBody(),
    );
  }
}

// Reusable body content (used inside HistoryScreen's TabBarView, with no
// Scaffold/AppBar of its own, and also embedded in SalesHistoryScreen above).
class SalesHistoryBody extends StatefulWidget {
  const SalesHistoryBody({super.key});

  @override
  State<SalesHistoryBody> createState() => _SalesHistoryBodyState();
}

class _SalesHistoryBodyState extends State<SalesHistoryBody> with AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  DateTime? _selectedDate;
  String _searchText = '';
  Timer? _searchDebounce;

  late final Stream<List<Invoice>> _invoicesStream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _invoicesStream = _firestoreService.getAllInvoices();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<Invoice>> _groupByDate(List<Invoice> invoices) {
    final Map<String, List<Invoice>> grouped = {};

    for (var invoice in invoices) {
      final dateKey = DateFormat('dd MMM yyyy').format(invoice.date.toDate());
      grouped.putIfAbsent(dateKey, () => []).add(invoice);
    }

    return grouped;
  }

  List<Invoice> _filterInvoices(List<Invoice> invoices) {
    return invoices.where((invoice) {
      final invoiceDate = invoice.date.toDate();

      if (_selectedDate != null) {
        final sameDate = invoiceDate.year == _selectedDate!.year &&
            invoiceDate.month == _selectedDate!.month &&
            invoiceDate.day == _selectedDate!.day;
        if (!sameDate) return false;
      }

      if (_searchText.isNotEmpty) {
        final invoiceNumber = invoice.invoiceNumber.toString().toLowerCase();
        if (!invoiceNumber.contains(_searchText.toLowerCase())) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _clearDate() {
    setState(() => _selectedDate = null);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final primary = Theme.of(context).colorScheme.primary;

    return StreamBuilder<List<Invoice>>(
      stream: _invoicesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primary));
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        final allInvoices = snapshot.data ?? [];

        if (allInvoices.isEmpty) {
          return _buildEmptyState(primary);
        }

        final filteredInvoices = _filterInvoices(allInvoices);

        double totalRevenue = 0;
        int totalItems = 0;

        for (var invoice in filteredInvoices) {
          totalRevenue += invoice.total;
          totalItems += invoice.totalItemCount;
        }

        final grouped = _groupByDate(filteredInvoices);
        final dateKeys = grouped.keys.toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('sales_search_field'),
                      controller: _searchController,
                      onChanged: (value) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(const Duration(milliseconds: 400), () {
                          if (!mounted) return;
                          setState(() => _searchText = value.trim());
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search invoice number...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 22),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchDebounce?.cancel();
                                  setState(() => _searchText = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: primary, width: 1.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: IconButton(
                      tooltip: 'Filter by date',
                      onPressed: _pickDate,
                      icon: Icon(Icons.tune_rounded, color: primary),
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedDate != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                child: Row(
                  children: [
                    Text(
                      'Date: ${DateFormat('dd MMM yyyy').format(_selectedDate!)}',
                      style: TextStyle(fontSize: 13, color: primary, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    TextButton(onPressed: _clearDate, child: const Text('Clear')),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'Items Sold',
                      value: totalItems.toString(),
                      iconColor: primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      icon: Icons.payments_rounded,
                      title: 'Total Revenue',
                      value: '৳${totalRevenue.toStringAsFixed(2)}',
                      iconColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: Row(
                children: [
                  const Text('Recent Sales', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text(
                    '${filteredInvoices.length} invoices',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Expanded(
              child: dateKeys.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 52, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No matching sales found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 5),
                          Text('Try another invoice number or date.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: dateKeys.length,
                      itemBuilder: (context, index) {
                        final dateKey = dateKeys[index];
                        final invoicesForDate = grouped[dateKey]!;

                        double dayTotal = 0;
                        for (var invoice in invoicesForDate) {
                          dayTotal += invoice.total;
                        }

                        return _buildDateSection(context, dateKey, invoicesForDate, dayTotal, primary);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.10), borderRadius: BorderRadius.circular(11)),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildDateSection(
    BuildContext context,
    String dateKey,
    List<Invoice> invoices,
    double dayTotal,
    Color primary,
  ) {
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
                '${invoices.length} invoice${invoices.length == 1 ? '' : 's'}  •  ৳${dayTotal.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
            children: invoices.map((invoice) => _buildInvoiceCard(context, invoice, primary)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice, Color primary) {
    final time = DateFormat('hh:mm a').format(invoice.date.toDate());

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Material(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(13),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ReceiptScreen(invoice: invoice)));
          },
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: primary.withOpacity(0.09), borderRadius: BorderRadius.circular(11)),
                  child: Icon(Icons.receipt_rounded, color: primary, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invoice #${invoice.invoiceNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Text('${invoice.totalItemCount} items',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('৳${invoice.total.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 14, color: Colors.green.shade700, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 5),
                    Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey.shade400),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primary) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(color: primary.withOpacity(0.09), shape: BoxShape.circle),
              child: Icon(Icons.receipt_long_rounded, size: 42, color: primary),
            ),
            const SizedBox(height: 20),
            const Text('No Sales Yet', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Your completed sales will appear here.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}