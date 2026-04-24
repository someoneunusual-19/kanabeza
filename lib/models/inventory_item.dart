// lib/models/inventory_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String id;
  final String storeId;
  final String name;
  final double price;
  final int stock;
  final String category;
  final DateTime? lastUpdated;
  final bool isSynced; // Useful for UI indicators

  InventoryItem({
    required this.id,
    required this.storeId,
    required this.name,
    this.price = 0.0,
    this.stock = 0,
    this.category = 'General',
    this.lastUpdated,
    this.isSynced = true,
  });

  /// Converts Firestore Document into a local InventoryItem object
  factory InventoryItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return InventoryItem(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      name: data['name'] ?? 'Unnamed Item',
      price: (data['price'] ?? 0.0).toDouble(),
      stock: data['stock'] ?? 0,
      category: data['category'] ?? 'General',
      // Handles the transition from Firestore Timestamp to Dart DateTime
      lastUpdated: (data['updatedAt'] as Timestamp?)?.toDate(),
      // 'hasPendingWrites' tells us if the local change has hit the cloud yet
      isSynced: !doc.metadata.hasPendingWrites,
    );
  }

  /// Converts local object to Map for Firestore upload
  Map<String, dynamic> toFirestore() {
    return {
      'storeId': storeId,
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      // CRITICAL: Always use serverTimestamp for offline-sync apps
      // to resolve conflicts between different devices.
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy for local state changes (Immutability pattern)
  InventoryItem copyWith({
    String? name,
    double? price,
    int? stock,
    String? category,
  }) {
    return InventoryItem(
      id: this.id,
      storeId: this.storeId,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      category: category ?? this.category,
      lastUpdated: DateTime.now(),
      isSynced: false, // Mark as dirty until sync confirms
    );
  }
}