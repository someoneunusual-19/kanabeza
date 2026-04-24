// lib/screens/manager/excel_bulk_entry.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kanabeza/models/app_user.dart';
import '../../theme/app_theme.dart';

class ExcelBulkEntry extends StatefulWidget {
  final AppUser user;
  const ExcelBulkEntry({super.key, required this.user});

  @override
  State<ExcelBulkEntry> createState() => _ExcelBulkEntryState();
}

class _ExcelBulkEntryState extends State<ExcelBulkEntry> {
  // A local list to hold our temporary "Draft" rows
  final List<Map<String, dynamic>> _rows = [
    {'name': '', 'price': '', 'stock': ''},
    {'name': '', 'price': '', 'stock': ''},
    {'name': '', 'price': '', 'stock': ''},
  ];

  bool _isSyncing = false;

  void _addNewRow() {
    setState(() {
      _rows.add({'name': '', 'price': '', 'stock': ''});
    });
  }

  Future<void> _handleBatchSync() async {
    setState(() => _isSyncing = true);
    
    final batch = FirebaseFirestore.instance.batch();
    int count = 0;

    for (var row in _rows) {
      // Only sync rows that have at least a product name
      if (row['name'].toString().trim().isNotEmpty) {
        final docRef = FirebaseFirestore.instance.collection('inventory').doc();
        batch.set(docRef, {
          'name': row['name'],
          'price': double.tryParse(row['price'].toString()) ?? 0.0,
          'stock': int.tryParse(row['stock'].toString()) ?? 0,
          'storeId': widget.user.storeId,
          'createdBy': widget.user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        count++;
      }
    }

    try {
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Successfully synced $count items"), backgroundColor: Colors.blueAccent),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Batch Sync Error: $e");
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text("Bulk Inventory Entry", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          if (_isSyncing)
            const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
          else
            TextButton.icon(
              onPressed: _handleBatchSync,
              icon: const Icon(Icons.cloud_upload_outlined, size: 20),
              label: const Text("Sync All"),
            )
        ],
      ),
      body: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppTheme.surface,
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text("Product Name", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("Price", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: Text("Stock", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          // Scrollable Grid Body
          Expanded(
            child: ListView.separated(
              itemCount: _rows.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: _buildCell(index, 'name', "e.g. Cement Bag")),
                      const SizedBox(width: 12),
                      Expanded(flex: 1, child: _buildCell(index, 'price', "0.0", isNum: true)),
                      const SizedBox(width: 12),
                      Expanded(flex: 1, child: _buildCell(index, 'stock', "0", isNum: true)),
                    ],
                  ),
                );
              },
            ),
          ),
          // Footer Controls
          Padding(
            padding: const EdgeInsets.all(20),
            child: OutlinedButton.icon(
              onPressed: _addNewRow,
              icon: const Icon(Icons.add),
              label: const Text("Add New Row"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: const BorderSide(color: Colors.white10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCell(int index, String key, String hint, {bool isNum = false}) {
    return TextField(
      onChanged: (val) => _rows[index][key] = val,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        border: InputBorder.none,
      ),
    );
  }
}