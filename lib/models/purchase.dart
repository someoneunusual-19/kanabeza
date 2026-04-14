import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

part 'purchase.g.dart';

@HiveType(typeId: 1)
class Purchase extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final String productId;
  @HiveField(3)
  final int quantity;
  @HiveField(4)
  final double costPrice;
  @HiveField(5)
  final double total;

  Purchase({
    required this.id,
    required this.date,
    required this.productId,
    required this.quantity,
    required this.costPrice,
    required this.total,
  });

  String get formattedDate => DateFormat('dd MMM yyyy').format(date);
}