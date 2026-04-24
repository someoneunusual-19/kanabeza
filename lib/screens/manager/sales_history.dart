// lib/screens/sales_history_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  // --- Export to CSV Logic ---
  Future<void> _exportToCSV(List<QueryDocumentSnapshot> docs) async {
    List<List<dynamic>> rows = [["Date", "Item", "Amount", "Seller"]];
    for (var doc in docs) {
      var data = doc.data() as Map<String, dynamic>;
      rows.add([data['ts']?.toDate().toString(), data['name'], data['amount'], data['createdBy']]);
    }
    String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getTemporaryDirectory();
    final file = File("${directory.path}/sales_report.csv");
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(file.path)], text: 'Kanabeza Sales Report');
  }

  // --- Export to PDF Logic ---
  Future<void> _exportToPDF(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Column(children: [
        pw.Header(level: 0, text: "Kanabeza Pro - Sales Report"),
        pw.TableHelper.fromTextArray(context: context, data: [
          ["Item", "Amount", "Date"],
          ...docs.map((d) => [d['name'], d['amount'].toString(), "Synced"])
        ]),
      ]);
    }));
    final directory = await getTemporaryDirectory();
    final file = File("${directory.path}/sales_report.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sales').orderBy('ts', descending: true).snapshots(),
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(
            title: const Text("Transaction History"),
            actions: [
              if (snapshot.hasData) ...[
                IconButton(icon: const Icon(Icons.description_outlined), onPressed: () => _exportToPDF(snapshot.data!.docs)),
                IconButton(icon: const Icon(Icons.grid_on_outlined), onPressed: () => _exportToCSV(snapshot.data!.docs)),
              ]
            ],
          ),
          body: snapshot.hasData 
            ? ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var sale = snapshot.data!.docs[index];
                  return ListTile(
                    title: Text(sale['name'] ?? "Unknown Item"),
                    subtitle: Text("Synced: ${sale['ts']?.toDate().toString().split('.')[0]}"),
                    trailing: Text("MK ${sale['amount']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  );
                },
              )
            : const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}