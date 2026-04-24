// lib/screens/seller/pos_entry_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SellerPOSEntry extends StatefulWidget {
  final String sellerId;
  final String storeId;
  const SellerPOSEntry({super.key, required this.sellerId, required this.storeId});

  @override
  State<SellerPOSEntry> createState() => _SellerPOSEntryState();
}

class _SellerPOSEntryState extends State<SellerPOSEntry> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  bool _isSyncing = false;

  Future<void> _recordSale() async {
    if (_amountController.text.isEmpty) return;

    final saleData = {
      'sellerId': widget.sellerId,
      'storeId': widget.storeId,
      'item': _itemController.text,
      'amount': double.tryParse(_amountController.text) ?? 0.0,
      'timestamp': FieldValue.serverTimestamp(), // Firestore handles the time sync
      'status': 'pending', // Local status
    };

    try {
      // This call returns immediately if offline, saving to local cache
      await FirebaseFirestore.instance.collection('sales').add(saleData);
      
      _amountController.clear();
      _itemController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Sale recorded (Auto-syncing in background)"),
          backgroundColor: Colors.blueAccent,
        ),
      );
    } catch (e) {
      debugPrint("Offline Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Deep Dark Canvas
      appBar: AppBar(
        title: const Text("New Sale", style: TextStyle(letterSpacing: 1.2)),
        actions: [
          // Visual Sync Indicator
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('sales')
                .where('sellerId', isEqualTo: widget.sellerId)
                .snapshots(includeMetadataChanges: true),
            builder: (context, snapshot) {
              final isPending = snapshot.data?.metadata.hasPendingWrites ?? false;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Icon(
                  isPending ? Icons.sync : Icons.cloud_done,
                  color: isPending ? Colors.amber : Colors.blueAccent,
                  size: 20,
                ),
              );
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildQuickInput("Item Name", _itemController, Icons.shopping_bag_outlined),
            const SizedBox(height: 20),
            _buildQuickInput("Amount (MWK)", _amountController, Icons.payments_outlined, isNumber: true),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _recordSale,
                child: const Text("COMPLETE SALE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInput(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.indigoAccent),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.indigoAccent)),
      ),
    );
  }
}