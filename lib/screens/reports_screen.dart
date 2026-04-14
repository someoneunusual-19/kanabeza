import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../services/hive_service.dart';
import '../widgets/custom_modals.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTimeRange? _selectedDateRange;

  // Filter sales based on date range
  List<Sale> _getFilteredSales(Box<Sale> salesBox) {
    final allSales = salesBox.values.toList();
    if (_selectedDateRange == null) return allSales;

    return allSales.where((sale) {
      return sale.date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
          sale.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  // Filter purchases based on date range
  List<Purchase> _getFilteredPurchases(Box<Purchase> purchaseBox) {
    final allPurchases = purchaseBox.values.toList();
    if (_selectedDateRange == null) return allPurchases;

    return allPurchases.where((purchase) {
      return purchase.date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
          purchase.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
    }).toList();
  }

  String _getDateRangeText() {
    if (_selectedDateRange == null) return 'All Time';
    return '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - '
        '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}';
  }

  // Custom Date Range Picker
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF81D4FA)),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  // Preset Filters
  void _filterThisMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    setState(() => _selectedDateRange = DateTimeRange(start: start, end: end));
  }

  void _filterThisYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31);
    setState(() => _selectedDateRange = DateTimeRange(start: start, end: end));
  }

  void _clearDateFilter() {
    setState(() => _selectedDateRange = null);
  }

  // Export to CSV
  Future<void> _exportToCSV() async {
    final filteredSales = _getFilteredSales(HiveService.salesBoxInstance);
    final filteredPurchases = _getFilteredPurchases(HiveService.purchasesBoxInstance);

    List<List<dynamic>> rows = [
      ['Type', 'Date', 'Product', 'Quantity', 'Unit Price', 'Total']
    ];

    for (var sale in filteredSales) {
      final product = HiveService.productsBoxInstance.get(sale.productId);
      rows.add([
        'Sale',
        sale.formattedDate,
        product?.name ?? '',
        sale.quantity,
        sale.sellingPrice,
        sale.total,
      ]);
    }

    for (var purchase in filteredPurchases) {
      final product = HiveService.productsBoxInstance.get(purchase.productId);
      rows.add([
        'Purchase',
        purchase.formattedDate,
        product?.name ?? '',
        purchase.quantity,
        purchase.costPrice,
        purchase.total,
      ]);
    }

    String csv = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/kanabeza_report_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);

    CustomModals.showSuccessModal(context, 'CSV exported successfully!\nSaved to Documents folder');
  }

  // Export to PDF
  Future<void> _exportToPDF() async {
    final filteredSales = _getFilteredSales(HiveService.salesBoxInstance);
    final filteredPurchases = _getFilteredPurchases(HiveService.purchasesBoxInstance);

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Kanabeza Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Period: ${_getDateRangeText()}'),
          pw.Text('Generated: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}'),
          pw.SizedBox(height: 30),

          pw.Text('Sales', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            data: [
              ['Date', 'Product', 'Qty', 'Selling Price', 'Total'],
              ...filteredSales.map((s) {
                final p = HiveService.productsBoxInstance.get(s.productId);
                return [
                  s.formattedDate,
                  p?.name ?? '',
                  s.quantity.toString(),
                  'MWK ${s.sellingPrice}',
                  'MWK ${s.total}'
                ];
              }),
            ],
          ),
          pw.SizedBox(height: 30),

          pw.Text('Purchases', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            data: [
              ['Date', 'Product', 'Qty', 'Cost Price', 'Total'],
              ...filteredPurchases.map((p) {
                final prod = HiveService.productsBoxInstance.get(p.productId);
                return [
                  p.formattedDate,
                  prod?.name ?? '',
                  p.quantity.toString(),
                  'MWK ${p.costPrice}',
                  'MWK ${p.total}'
                ];
              }),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
    CustomModals.showSuccessModal(context, 'PDF generated!\nReady for printing or sharing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Ledger'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Filter by Date',
            onPressed: _selectDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Export CSV',
            onPressed: _exportToCSV,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Export PDF',
            onPressed: _exportToPDF,
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: HiveService.salesBoxInstance.listenable(),
        builder: (context, Box<Sale> salesBox, _) {
          return ValueListenableBuilder(
            valueListenable: HiveService.purchasesBoxInstance.listenable(),
            builder: (context, Box<Purchase> purchaseBox, _) {
              return ValueListenableBuilder(
                valueListenable: HiveService.productsBoxInstance.listenable(),
                builder: (context, Box<Product> productBox, _) {
                  final filteredSales = _getFilteredSales(salesBox);
                  final filteredPurchases = _getFilteredPurchases(purchaseBox);
                  final products = productBox.values.toList();

                  // Calculations (filtered)
                  final totalSales = filteredSales.fold<double>(0, (sum, s) => sum + s.total);
                  final cogs = filteredSales.fold<double>(0, (sum, s) => sum + (s.quantity * s.costPrice));
                  final grossProfit = totalSales - cogs;
                  final totalStockValue = products.fold<double>(
                    0,
                    (sum, p) => sum + (p.currentStock * p.costPrice),
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Business Overview',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Period: ${_getDateRangeText()}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),

                        // Quick Preset Buttons
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildPresetButton('This Month', _filterThisMonth),
                              const SizedBox(width: 8),
                              _buildPresetButton('This Year', _filterThisYear),
                              const SizedBox(width: 8),
                              _buildPresetButton('All Time', _clearDateFilter),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Summary Cards
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Total Sales',
                                'MWK ${totalSales.toStringAsFixed(0)}',
                                Icons.point_of_sale,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Gross Profit',
                                'MWK ${grossProfit.toStringAsFixed(0)}',
                                Icons.trending_up,
                                grossProfit >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Stock Value',
                                'MWK ${totalStockValue.toStringAsFixed(0)}',
                                Icons.inventory_2,
                                const Color(0xFF81D4FA),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Transactions',
                                '${filteredSales.length + filteredPurchases.length}',
                                Icons.receipt_long,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Ledger Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ledger',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                            ),
                            if (_selectedDateRange != null)
                              TextButton.icon(
                                onPressed: _clearDateFilter,
                                icon: const Icon(Icons.clear, size: 18),
                                label: const Text('Clear Filter'),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (filteredSales.isEmpty && filteredPurchases.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(60),
                              child: Text('No transactions found in selected period'),
                            ),
                          )
                        else ...[
                          if (filteredSales.isNotEmpty) ...[
                            const Text('Sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...filteredSales.map((sale) {
                              final product = productBox.get(sale.productId);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.arrow_upward, color: Colors.green),
                                  title: Text(product?.name ?? 'Sale'),
                                  subtitle: Text(sale.formattedDate),
                                  trailing: Text(
                                    '+ MWK ${sale.total.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }),
                          ],
                          const SizedBox(height: 24),
                          if (filteredPurchases.isNotEmpty) ...[
                            const Text('Purchases (Stock In)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...filteredPurchases.map((purchase) {
                              final product = productBox.get(purchase.productId);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.arrow_downward, color: Colors.orange),
                                  title: Text(product?.name ?? 'Purchase'),
                                  subtitle: Text(purchase.formattedDate),
                                  trailing: Text(
                                    '- MWK ${purchase.total.toStringAsFixed(0)}',
                                    style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // Preset Button Widget
  Widget _buildPresetButton(String label, VoidCallback onTap) {
    final bool isActive = (_selectedDateRange == null && label == 'All Time') ||
        (label == 'This Month' && _selectedDateRange?.start.month == DateTime.now().month) ||
        (label == 'This Year' && _selectedDateRange?.start.year == DateTime.now().year);

    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? const Color(0xFF81D4FA) : Colors.grey[300],
        foregroundColor: isActive ? Colors.white : Colors.black87,
        elevation: isActive ? 4 : 1,
      ),
      child: Text(label),
    );
  }

  // Summary Card Widget
  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}