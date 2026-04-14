import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/product.dart';
import '../models/purchase.dart';
import '../services/hive_service.dart';
import '../widgets/custom_modals.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _uuid = const Uuid();
  String _searchQuery = '';

  // Controllers for Add Product Modal
  final _nameController = TextEditingController();
  final _costController = TextEditingController();
  final _sellController = TextEditingController();
  final _stockController = TextEditingController();

  void _clearControllers() {
    _nameController.clear();
    _costController.clear();
    _sellController.clear();
    _stockController.clear();
  }

  // Show beautiful modal to add new product
  void _showAddProductModal() {
    _clearControllers();

    CustomModals.showKanabezaModal(
      context: context,
      heightFactor: 0.68,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Product',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cost Price (MWK)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _sellController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Selling Price (MWK)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Initial Stock',
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

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
                    onPressed: _addProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF81D4FA),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('ADD PRODUCT', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addProduct() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product name is required')),
      );
      return;
    }

    final product = Product(
      id: _uuid.v4(),
      name: name,
      costPrice: double.tryParse(_costController.text) ?? 0.0,
      sellingPrice: double.tryParse(_sellController.text) ?? 0.0,
      currentStock: int.tryParse(_stockController.text) ?? 0,
    );

    HiveService.productsBoxInstance.put(product.id, product);
    Navigator.pop(context);

    CustomModals.showSuccessModal(context, '$name added successfully!');
  }

  // Show Add Stock Modal
  void _showAddStockModal(Product product) {
    final qtyController = TextEditingController();
    final costController = TextEditingController(text: product.costPrice.toString());

    CustomModals.showKanabezaModal(
      context: context,
      heightFactor: 0.55,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Stock - ${product.name}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity to Add',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cost per Unit (MWK)',
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _addStock(product, qtyController.text, costController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF81D4FA),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('ADD STOCK'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addStock(Product product, String qtyStr, String costStr) {
    final qty = int.tryParse(qtyStr) ?? 0;
    final newCost = double.tryParse(costStr) ?? product.costPrice;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be greater than 0')),
      );
      return;
    }

    // Update product
    product.currentStock += qty;
    product.costPrice = newCost;
    product.save();

    // Record purchase
    final purchase = Purchase(
      id: _uuid.v4(),
      date: DateTime.now(),
      productId: product.id,
      quantity: qty,
      costPrice: newCost,
      total: qty * newCost,
    );

    HiveService.purchasesBoxInstance.put(purchase.id, purchase);

    Navigator.pop(context);
    CustomModals.showSuccessModal(context, '$qty units added to ${product.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products & Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Products',
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(
                  onQueryChanged: (query) => setState(() => _searchQuery = query),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProductModal,
        child: const Icon(Icons.add),
      ),
      body: ValueListenableBuilder(
        valueListenable: HiveService.productsBoxInstance.listenable(),
        builder: (context, Box<Product> box, _) {
          var products = box.values.toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          // Apply search filter
          if (_searchQuery.isNotEmpty) {
            products = products.where((p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          }

          if (products.isEmpty) {
            return const Center(
              child: Text(
                'No products found.\nTap + to add your first product.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              final stockValue = product.currentStock * product.costPrice;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFF81D4FA),
                    child: Text(
                      product.name[0].toUpperCase(),
                      style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${product.currentStock} units in stock\nCost: MWK ${product.costPrice.toStringAsFixed(0)}',
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'MWK ${stockValue.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Color(0xFF81D4FA), size: 28),
                        onPressed: () => _showAddStockModal(product),
                      ),
                    ],
                  ),
                  onLongPress: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Product?'),
                        content: Text('Are you sure you want to delete ${product.name}?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              product.delete();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
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
    _nameController.dispose();
    _costController.dispose();
    _sellController.dispose();
    _stockController.dispose();
    super.dispose();
  }
}

// Search Delegate for Products
class ProductSearchDelegate extends SearchDelegate<String> {
  final Function(String) onQueryChanged;

  ProductSearchDelegate({required this.onQueryChanged});

  @override
  List<Widget> buildActions(BuildContext context) => [
        IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
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