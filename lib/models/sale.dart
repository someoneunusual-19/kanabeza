import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'sale.g.dart';

@HiveType(typeId: 2)
class Sale extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final String productId;
  @HiveField(3)
  final int quantity;
  @HiveField(4)
  final double sellingPrice;
  @HiveField(5)
  final double costPrice; // cost at time of sale for accurate COGS
  @HiveField(6)
  final double total;

  Sale({
    required this.id,
    required this.date,
    required this.productId,
    required this.quantity,
    required this.sellingPrice,
    required this.costPrice,
    required this.total,
  });

  String get formattedDate => DateFormat('dd MMM yyyy').format(date);
}