import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kanabeza/models/app_user.dart';

class EntryBottomSheet {
  static void show(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EntrySheetContent(user: user),
    );
  }
}

class _EntrySheetContent extends StatefulWidget {
  final AppUser user;
  const _EntrySheetContent({required this.user});

  @override
  State<_EntrySheetContent> createState() => _EntrySheetContentState();
}

class _EntrySheetContentState extends State<_EntrySheetContent> {
  // Local buffer for "Excel-style" multi-entry
  final List<Map<String, dynamic>> _buffer = [{}];

  Future<void> _processSync() async {
    final batch = FirebaseFirestore.instance.batch();
    // Managers edit Inventory; Sellers record Sales
    final collectionPath = widget.user.role == UserRole.manager ? 'inventory' : 'sales';

    for (var entry in _buffer) {
      if (entry['name'] != null && entry['name'].toString().isNotEmpty) {
        var docRef = FirebaseFirestore.instance.collection(collectionPath).doc();
        batch.set(docRef, {
          ...entry,
          'storeId': widget.user.storeId,
          'createdBy': widget.user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await batch.commit(); // Fires locally immediately (Offline-First)
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _buffer.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(child: _field("Item Name", (val) => _buffer[index]['name'] = val)),
                    const SizedBox(width: 10),
                    SizedBox(width: 100, child: _field("Val", (val) => _buffer[index]['amount'] = val, isNum: true)),
                  ],
                ),
              ),
            ),
          ),
          if (widget.user.role == UserRole.manager)
            TextButton.icon(
              onPressed: () => setState(() => _buffer.add({})),
              icon: const Icon(Icons.add),
              label: const Text("Add Another Row"),
            ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _processSync,
              child: const Text("SYNC TO CLOUD", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String hint, Function(String) onChanged, {bool isNum = false}) {
    return TextField(
      onChanged: onChanged,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    );
  }
}