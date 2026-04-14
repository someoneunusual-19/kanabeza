import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../services/hive_service.dart';
import '../widgets/custom_modals.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _uuid = const Uuid();
  final _qtyController = TextEditingController();
  String _searchQuery = '';
  Product? _selectedProductForSale;

  // Show beautiful modal to record a new sale
  void _showRecordSaleModal() {
    _qtyController.clear();
    _selectedProductForSale = null;

    CustomModals.showKanabezaModal(
      context: context,
      heightFactor: 0.72,
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Record New Sale',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Product Selection
                const Text('Select Product', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ValueListenableBuilder(
                  valueListenable: HiveService.productsBoxInstance.listenable(),
                  builder: (context, Box<Product> box, _) {
                    final products = box.values.toList()
                      ..sort((a, b) => a.name.compareTo(b.name));

                    return DropdownButtonFormField<Product>(
                      value: _selectedProductForSale,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      hint: const Text('Choose a product to sell'),
                      items: products.map((product) {
                        return DropdownMenuItem<Product>(
                          value: product,
                          child: Text('${product.name} (${product.currentStock} in stock)'),
                        );
                      }).toList(),
                      onChanged: (product) {
                        setModalState(() => _selectedProductForSale = product);
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Quantity Input
                TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity Sold',
                    border: OutlineInputBorder(),
                    hintText: 'Enter quantity',
                  ),
                ),

                const SizedBox(height: 12),
                if (_selectedProductForSale != null)
                  Text(
                    'Selling Price: MWK ${_selectedProductForSale!.sellingPrice.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.w500),
                  ),

                const Spacer(),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _recordSale,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF81D4FA),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('RECORD SALE', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Record the sale
  void _recordSale() {
    if (_selectedProductForSale == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a product')),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text.trim()) ?? 0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than 0')),
      );
      return;
    }

    if (qty > _selectedProductForSale!.currentStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only ${_selectedProductForSale!.currentStock} units available in stock')),
      );
      return;
    }

    // Create and save sale
    final sale = Sale(
      id: _uuid.v4(),
      date: DateTime.now(),
      productId: _selectedProductForSale!.id,
      quantity: qty,
      sellingPrice: _selectedProductForSale!.sellingPrice,
      costPrice: _selectedProductForSale!.costPrice,
      total: qty * _selectedProductForSale!.sellingPrice,
    );

    HiveService.salesBoxInstance.put(sale.id, sale);

    // Reduce stock
    _selectedProductForSale!.currentStock -= qty;
    _selectedProductForSale!.save();

    Navigator.pop(context);

    CustomModals.showSuccessModal(
      context,
      'Sale Recorded!\n${qty} × ${_selectedProductForSale!.name}',
      onDone: () => setState(() {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Sales',
            onPressed: () {
              showSearch(
                context: context,
                delegate: SaleSearchDelegate(
                  onQueryChanged: (query) => setState(() => _searchQuery = query),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRecordSaleModal,
        icon: const Icon(Icons.point_of_sale),
        label: const Text('New Sale'),
        backgroundColor: const Color(0xFF81D4FA),
      ),
      body: ValueListenableBuilder(
        valueListenable: HiveService.salesBoxInstance.listenable(),
        builder: (context, Box<Sale> box, _) {
          var sales = box.values.toList()
            ..sort((a, b) => b.date.compareTo(a.date)); // Newest first

          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            sales = sales.where((sale) {
              final product = HiveService.productsBoxInstance.get(sale.productId);
              return (product?.name ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();
          }

          if (sales.isEmpty) {
            return const Center(
              child: Text(
                'No sales recorded yet.\nTap the + button to record your first sale.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              final product = HiveService.productsBoxInstance.get(sale.productId);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF81D4FA).withOpacity(0.2),
                    child: const Icon(Icons.receipt_long, color: Color(0xFF81D4FA)),
                  ),
                  title: Text(
                    product?.name ?? 'Unknown Product',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  subtitle: Text(
                    '${sale.quantity} units • ${sale.formattedDate}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'MWK ${sale.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }
}

// Search Delegate for Sales Screen
class SaleSearchDelegate extends SearchDelegate<String> {
  final Function(String) onQueryChanged;

  SaleSearchDelegate({required this.onQueryChanged});

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => const SizedBox();

  @override
  Widget buildSuggestions(BuildContext context) {
    onQueryChanged(query);
    return const SizedBox();
  }
}