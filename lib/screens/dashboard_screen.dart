// lib/screens/dashboard_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kanabeza/models/app_user.dart';
import '../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  final AppUser user;
  const DashboardScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(user.role == UserRole.manager ? "Manager Terminal" : "Seller Terminal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Only fetch data belonging to THIS store
        stream: FirebaseFirestore.instance
            .collection('sales')
            .where('storeId', isEqualTo: user.storeId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          double totalRevenue = 0;
          int totalTransactions = snapshot.data?.docs.length ?? 0;

          for (var doc in snapshot.data?.docs ?? []) {
            totalRevenue += (doc['amount'] ?? 0).toDouble();
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                "Welcome back,",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              Text(
                user.email.split('@')[0].toUpperCase(),
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              
              // Key Metrics Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Daily Revenue", 
                      "MK ${totalRevenue.toStringAsFixed(0)}", 
                      Icons.account_balance_wallet_rounded,
                      Colors.blueAccent
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      "Sales Count", 
                      totalTransactions.toString(), 
                      Icons.shopping_bag_rounded,
                      Colors.orangeAccent
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              const Text(
                "Inventory Alerts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildInventoryAlerts(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(val, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInventoryAlerts() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('inventory')
          .where('storeId', isEqualTo:  user.storeId)
          .where('stock', isGreaterThanOrEqualTo:  5) // Low stock threshold
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("All stock levels are healthy.", style: TextStyle(color: Colors.white24));
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              title: Text(doc['name']),
              subtitle: Text("Only ${doc['stock']} left in stock"),
              trailing: const Text("Restock", style: TextStyle(color: Colors.indigoAccent)),
            );
          }).toList(),
        );
      },
    );
  }
}